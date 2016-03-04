package awsprovider

import (
	"errors"
	"fmt"
	"strconv"

	"github.com/satori/go.uuid"
	"golang.org/x/net/context"

	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/userdata"
)

func (s *Stack) SetAwsRegion(region string) error {
	t := s.Builder.Template

	var provider struct {
		Aws struct {
			Region    string `hcl:"region"`
			AccessKey string `hcl:"access_key"`
			SecretKey string `hcl:"secret_key"`
		}
	}

	if err := t.DecodeProvider(&provider); err != nil {
		return err
	}

	if provider.Aws.Region == "" {
		t.Provider["aws"] = map[string]interface{}{
			"region":     region,
			"access_key": provider.Aws.AccessKey,
			"secret_key": provider.Aws.SecretKey,
		}
	} else if !stackplan.IsVariable(provider.Aws.Region) && provider.Aws.Region != region {
		return fmt.Errorf("region is already set as '%s'. Can't override it with: %s",
			provider.Aws.Region, region)
	}

	return t.Flush()
}

func (s *Stack) InjectAWSData(ctx context.Context, username string, expandUserData bool) (stackplan.KiteMap, error) {
	t := s.Builder.Template

	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	var meta *AwsMeta
	for _, cred := range s.Builder.Credentials {
		if cred.Provider != "aws" {
			continue
		}

		meta = cred.Meta.(*AwsMeta)

		if err := meta.BootstrapValid(); err != nil {
			return nil, fmt.Errorf("invalid bootstrap metadata for %q: %s", cred.Identifier, err)
		}

		break
	}

	if meta == nil {
		s.Log.Debug("No AWS data found to be injected")
		return nil, nil
	}

	var resource struct {
		AwsInstance map[string]map[string]interface{} `hcl:"aws_instance"`
	}

	if err := t.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.AwsInstance) == 0 {
		return nil, fmt.Errorf("instance is empty: %v", resource.AwsInstance)
	}

	kiteIDs := make(stackplan.KiteMap)

	for resourceName, instance := range resource.AwsInstance {
		instance["key_name"] = meta.KeyPair

		// if nothing is provided or the ami is empty use default Ubuntu AMI's
		if a, ok := instance["ami"]; !ok {
			instance["ami"] = meta.AMI
		} else {
			if ami, ok := a.(string); ok && ami == "" {
				instance["ami"] = meta.AMI
			}
		}

		// only ovveride if the user doesn't provider it's own subnet_id
		if instance["subnet_id"] == nil {
			instance["subnet_id"] = meta.Subnet
			instance["security_groups"] = []string{meta.SG}
		}

		// means there will be several instances, we need to create a userdata
		// with count interpolation, because each machine must have an unique
		// kite id.
		var count int = 1
		if c, ok := instance["count"]; ok {
			// we receive it as int
			cn, ok := c.(int)
			if !ok {
				return nil, fmt.Errorf("count statement should be an integer, got: %+v, %T", c, c)
			} else {
				count = cn
			}
		}

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: username,
			Groups:   []string{"sudo"},
			Hostname: username, // no typo here. hostname = username
		}

		// prepend custom script if available - the script needs to be
		// base64-encoded to ensure the eventual formatting and terraform
		// interpolation won't break YAML encoding of the cloud-init
		// script; since most likely the user_data requires terraform
		// interpolation, let it be interpolated as variable, and base64-encode
		// it during the interpolation.
		//
		// Note on implementation: since variables themselves cannot be
		// additionally interpolated, as terraform would fail with:
		//
		//   * Variable 'userdata_example': cannot contain interpolations
		//
		// We're using special "null_resource" to have the the interpolation
		// kick in. For more details see:
		//
		//   https://github.com/hashicorp/terraform/issues/4084
		//
		if cmd, ok := instance["user_data"].(string); ok && expandUserData {
			userCfg.UserData = fmt.Sprintf("${base64encode(null_resource.%s.triggers.user_data)}", resourceName)

			nullRes, ok := t.Resource["null_resource"].(map[string]interface{})
			if !ok {
				nullRes = make(map[string]interface{})
				t.Resource["null_resource"] = nullRes
			}

			res, ok := nullRes[resourceName].(map[string]interface{})
			if !ok {
				res = make(map[string]interface{})
				nullRes[resourceName] = res
			}

			triggers, ok := res["triggers"].(map[string]interface{})
			if !ok {
				triggers = make(map[string]interface{})
				res["triggers"] = triggers

				// This field is a nop, it works around the following terraform
				// parsing bug:
				//
				//   resource must be followed by exactly two strings, a type and a name
				//
				// TODO(rjeczalik): report and/or fix
				res["depends_on"] = []interface{}{}
			}

			triggers["user_data"] = stackplan.UserData(cmd)
		}

		kiteKeyName := fmt.Sprintf("kitekeys_%s", resourceName)

		// will be replaced with the kitekeys we create below
		userCfg.KiteKey = fmt.Sprintf("${lookup(var.%s, count.index)}", kiteKeyName)

		userdata, err := sess.Userdata.Create(userCfg)
		if err != nil {
			return nil, err
		}

		instance["user_data"] = string(userdata)

		// create independent kiteKey for each machine and create a Terraform
		// lookup map, which is used in conjuctuon with the `count.index`
		countKeys := map[string]string{}
		for i := 0; i < count; i++ {
			// create a new kite id for every new aws resource
			kiteUUID := uuid.NewV4()

			kiteId := kiteUUID.String()

			kiteKey, err := sess.Userdata.Keycreator.Create(username, kiteId)
			if err != nil {
				return nil, err
			}

			// if the count is greater than 1, terraform will change the labels
			// and append a number(starting with index 0) to each label
			if count != 1 {
				kiteIDs[resourceName+"."+strconv.Itoa(i)] = kiteId
			} else {
				kiteIDs[resourceName] = kiteId
			}

			countKeys[strconv.Itoa(i)] = kiteKey
		}

		t.Variable[kiteKeyName] = map[string]interface{}{
			"default": countKeys,
		}

		resource.AwsInstance[resourceName] = instance
	}

	t.Resource["aws_instance"] = resource.AwsInstance

	if err := t.Flush(); err != nil {
		return nil, err
	}

	if err := t.ShadowVariables("FORBIDDEN", "aws_access_key", "aws_secret_key"); err != nil {
		return nil, err
	}

	return kiteIDs, nil
}
