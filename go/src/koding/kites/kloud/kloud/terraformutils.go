package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/userdata"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"time"

	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/fatih/structs"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite/protocol"
	"github.com/mitchellh/mapstructure"
	"github.com/nu7hatch/gouuid"
)

type TerraformMachine struct {
	Provider    string            `json:"provider"`
	Label       string            `json:"label"`
	Region      string            `json:"region"`
	QueryString string            `json:"queryString,omitempty"`
	Attributes  map[string]string `json:"attributes"`
}

type Machines struct {
	Machines []TerraformMachine `json:"machines"`
}

type buildData struct {
	Template string
	Region   string
	KiteIds  map[string]string
}

type terraformData struct {
	Creds   []*terraformCredential
	Account *models.Account `structs:"account"`
	Group   *models.Group   `structs:"group"`
	User    *models.User    `structs:"user"`
}

type terraformCredential struct {
	Provider   string
	Identifier string
	Data       map[string]string `mapstructure:"data"`
}

type terraformTemplate struct {
	Resource struct {
		Aws_Instance map[string]map[string]interface{} `json:"aws_instance"`
	} `json:"resource"`
	Provider struct {
		Aws struct {
			Region    string `json:"region"`
			AccessKey string `json:"access_key"`
			SecretKey string `json:"secret_key"`
		} `json:"aws"`
	} `json:"provider"`
	Variable map[string]map[string]interface{} `json:"variable,omitempty"`
}

func (m *Machines) AppendRegion(region string) {
	for i, machine := range m.Machines {
		machine.Region = region
		m.Machines[i] = machine
	}
}

func (m *Machines) AppendQueryString(queryStrings map[string]string) {
	for i, machine := range m.Machines {
		queryString := queryStrings[machine.Label]
		machine.QueryString = protocol.Kite{ID: queryString}.String()
		m.Machines[i] = machine
	}
}

// WithLabel returns the machine with the associated label
func (m *Machines) WithLabel(label string) (TerraformMachine, error) {
	for _, machine := range m.Machines {
		if machine.Label == label {
			return machine, nil
		}
	}

	return TerraformMachine{}, fmt.Errorf("couldn't find machine with label '%s", label)
}

// region returns the region from the credential data
func (t *terraformCredential) region() (string, error) {
	// for now we support only aws
	if t.Provider != "aws" {
		return "", fmt.Errorf("provider '%s' is not supported", t.Provider)
	}

	region := t.Data["region"]
	if region == "" {
		return "", fmt.Errorf("region for identifer '%s' is not set", t.Identifier)
	}

	return region, nil
}

func (t *terraformCredential) awsCredentials() (string, string, error) {
	if t.Provider != "aws" {
		return "", "", fmt.Errorf("provider '%s' is not supported", t.Provider)
	}

	// we do not check for key existency here because the key might exists but
	// with an empty value, so just checking for the emptiness of the value is
	// better
	accessKey := t.Data["access_key"]
	if accessKey == "" {
		return "", "", fmt.Errorf("accessKey for identifier '%s' is not set", t.Identifier)
	}

	secretKey := t.Data["secret_key"]
	if secretKey == "" {
		return "", "", fmt.Errorf("secretKey for identifier '%s' is not set", t.Identifier)
	}

	return accessKey, secretKey, nil
}

// appendAWSVariable appends the credentials aws data to the given template and
// returns it back.
func (t *terraformCredential) appendAWSVariable(template string) (string, error) {
	var data struct {
		Output   map[string]map[string]interface{} `json:"output,omitempty"`
		Resource map[string]map[string]interface{} `json:"resource,omitempty"`
		Provider struct {
			Aws struct {
				Region    string `json:"region"`
				AccessKey string `json:"access_key"`
				SecretKey string `json:"secret_key"`
			} `json:"aws"`
		} `json:"provider"`
		Variable map[string]map[string]interface{} `json:"variable,omitempty"`
	}

	if err := json.Unmarshal([]byte(template), &data); err != nil {
		return "", err
	}

	credRegion := t.Data["region"]
	if credRegion == "" {
		return "", fmt.Errorf("region for identifier '%s' is not set", t.Identifier)
	}

	// if region is not added, add it via credRegion
	region := data.Provider.Aws.Region
	if region == "" {
		data.Provider.Aws.Region = credRegion
	} else if !isVariable(region) && region != credRegion {
		// compare with the provider block's region. Don't allow if they are
		// different.
		return "", fmt.Errorf("region in the provider block doesn't match the region in credential data. Provider block: '%s'. Credential data: '%s'", region, credRegion)
	}

	if data.Variable == nil {
		data.Variable = make(map[string]map[string]interface{})
	}

	accessKey, secretKey, err := t.awsCredentials()
	if err != nil {
		return "", err
	}

	data.Variable["aws_access_key"] = map[string]interface{}{
		"default": accessKey,
	}

	data.Variable["aws_secret_key"] = map[string]interface{}{
		"default": secretKey,
	}

	data.Variable["region"] = map[string]interface{}{
		"default": credRegion,
	}

	out, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return "", err
	}

	return string(out), nil
}

func machinesFromState(state *terraform.State) (*Machines, error) {
	if state.Modules == nil {
		return nil, errors.New("state modules is empty")
	}

	out := &Machines{
		Machines: make([]TerraformMachine, 0),
	}

	for _, m := range state.Modules {
		for resource, r := range m.Resources {
			if r.Primary == nil {
				continue
			}

			provider, label, err := parseProviderAndLabel(resource)
			if err != nil {
				return nil, err
			}

			attrs := make(map[string]string, len(r.Primary.Attributes))
			for key, val := range r.Primary.Attributes {
				attrs[key] = val
			}

			out.Machines = append(out.Machines, TerraformMachine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return out, nil
}

func machinesFromPlan(plan *terraform.Plan) (*Machines, error) {
	if plan.Diff == nil {
		return nil, errors.New("plan diff is empty")
	}

	if plan.Diff.Modules == nil {
		return nil, errors.New("plan diff module is empty")
	}

	out := &Machines{
		Machines: make([]TerraformMachine, 0),
	}

	for _, d := range plan.Diff.Modules {
		if d.Resources == nil {
			continue
		}

		for providerResource, r := range d.Resources {
			if r.Attributes == nil {
				continue
			}

			attrs := make(map[string]string, len(r.Attributes))
			for name, a := range r.Attributes {
				attrs[name] = a.New
			}

			provider, label, err := parseProviderAndLabel(providerResource)
			if err != nil {
				return nil, err
			}

			out.Machines = append(out.Machines, TerraformMachine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return out, nil
}

func parseProviderAndLabel(resource string) (string, string, error) {
	// resource is in the form of "aws_instance.foo.bar"
	splitted := strings.Split(resource, "_")
	if len(splitted) < 2 {
		return "", "", fmt.Errorf("provider resource is unknown: %v", splitted)
	}

	// splitted[1]: instance.foo.bar
	resourceSplitted := strings.SplitN(splitted[1], ".", 2)

	provider := splitted[0]      // aws
	label := resourceSplitted[1] // foo.bar

	return provider, label, nil
}

func (t *terraformTemplate) injectKodingData(data *terraformData) {
	var properties = []struct {
		collection string
		fieldToAdd map[string]bool
	}{
		{"User",
			map[string]bool{
				"username": true,
				"email":    true,
			},
		},
		{"Account",
			map[string]bool{
				"profile": true,
			},
		},
		{"Group",
			map[string]bool{
				"title": true,
				"slug":  true,
			},
		},
	}

	for _, p := range properties {
		model, ok := structs.New(data).FieldOk(p.collection)
		if !ok {
			continue
		}

		for _, field := range model.Fields() {
			fieldName := strings.ToLower(field.Name())
			// check if the user set a field tag
			if field.Tag("bson") != "" {
				fieldName = field.Tag("bson")
			}

			exists := p.fieldToAdd[fieldName]

			// we need to declare to call it recursively
			var addVariable func(*structs.Field, string, bool)

			addVariable = func(field *structs.Field, varName string, allow bool) {
				if !allow {
					return
				}

				// nested structs, call again
				if field.Kind() == reflect.Struct {
					for _, f := range field.Fields() {
						fieldName := strings.ToLower(f.Name())
						// check if the user set a field tag
						if f.Tag("bson") != "" {
							fieldName = f.Tag("bson")
						}
						newName := varName + "_" + fieldName
						addVariable(f, newName, true)
					}
					return
				}

				t.Variable[varName] = map[string]interface{}{
					"default": field.Value(),
				}
			}

			varName := "koding_" + strings.ToLower(p.collection) + "_" + fieldName
			addVariable(field, varName, exists)
		}
	}
}

func injectKodingData(ctx context.Context, content, username string, data *terraformData) (*buildData, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	awsOutput := &AwsBootstrapOutput{}
	for _, cred := range data.Creds {
		if cred.Provider != "aws" {
			continue
		}

		if err := mapstructure.Decode(cred.Data, &awsOutput); err != nil {
			return nil, err
		}
	}

	if structs.HasZero(awsOutput) {
		return nil, fmt.Errorf("Bootstrap data is incomplete: %v", awsOutput)
	}

	var template *terraformTemplate
	if err := json.Unmarshal([]byte(content), &template); err != nil {
		return nil, err
	}

	// inject koding variables, in the form of koding_user_foo, koding_group_name, etc..
	template.injectKodingData(data)

	if len(template.Resource.Aws_Instance) == 0 {
		return nil, fmt.Errorf("instance is empty: %v", template.Resource.Aws_Instance)
	}

	kiteIds := make(map[string]string)

	for resourceName, instance := range template.Resource.Aws_Instance {
		instance["key_name"] = awsOutput.KeyPair

		// if nothing is provided or the ami is empty use default Ubuntu AMI's
		if a, ok := instance["ami"]; !ok {
			instance["ami"] = awsOutput.AMI
		} else {
			if ami, ok := a.(string); ok && ami == "" {
				instance["ami"] = awsOutput.AMI
			}
		}

		// only ovveride if the user doesn't provider it's own subnet_id
		if instance["subnet_id"] == nil {
			instance["subnet_id"] = awsOutput.Subnet
			instance["security_groups"] = []string{awsOutput.SG}
		}

		// means there will be several instances, we need to create a userdata
		// with count interpolation, because each machine must have an unique
		// kite id.
		var count int = 1
		if c, ok := instance["count"]; ok {
			// we receive it as float64
			if cFloat, ok := c.(float64); !ok {
				return nil, fmt.Errorf("count statement should be an integer, got: %+v", c)
			} else {
				count = int(cFloat)
			}
		}

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: username,
			Groups:   []string{"sudo"},
			Hostname: username, // no typo here. hostname = username
		}

		// prepend custom script if available
		if c, ok := instance["user_data"]; ok {
			if customCMD, ok := c.(string); ok {
				userCfg.CustomCMD = customCMD
			}
		}

		// will be replaced with the kitekeys we create below
		userCfg.KiteKey = "${lookup(var.kitekeys, count.index)}"

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
			kiteUUID, err := uuid.NewV4()
			if err != nil {
				return nil, err
			}

			kiteId := kiteUUID.String()

			kiteKey, err := sess.Userdata.Keycreator.Create(username, kiteId)
			if err != nil {
				return nil, err
			}

			// if the count is greater than 1, terraform will change the labels
			// and append a number(starting with index 0) to each label
			if count != 1 {
				kiteIds[resourceName+"."+strconv.Itoa(i)] = kiteId
			} else {
				kiteIds[resourceName] = kiteId
			}

			countKeys[strconv.Itoa(i)] = kiteKey
		}

		template.Variable["kitekeys"] = map[string]interface{}{
			"default": countKeys,
		}

		template.Resource.Aws_Instance[resourceName] = instance
	}

	out, err := json.MarshalIndent(template, "", "  ")
	if err != nil {
		return nil, err
	}

	b := &buildData{
		Template: string(out),
		KiteIds:  kiteIds,
		Region:   template.Provider.Aws.Region,
	}

	return b, nil
}

func varsFromCredentials(creds *terraformData) map[string]string {
	vars := make(map[string]string, 0)
	for _, cred := range creds.Creds {
		for k, v := range cred.Data {
			vars[k] = v
		}
	}
	return vars
}

func checkKlients(ctx context.Context, kiteIds map[string]string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	var wg sync.WaitGroup
	var mu sync.Mutex // protects multierror and outputs
	var multiErrors error

	check := func(label, kiteId string) error {
		queryString := protocol.Kite{ID: kiteId}.String()
		klientRef, err := klient.NewWithTimeout(sess.Kite, queryString, time.Minute*5)
		if err != nil {
			return err
		}
		defer klientRef.Close()

		return klientRef.Ping()
	}

	for l, k := range kiteIds {
		wg.Add(1)
		go func(label, kiteId string) {
			if err := check(label, kiteId); err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors,
					fmt.Errorf("Couldn't check '%s:%s'", label, kiteId))
				mu.Unlock()
			}
			wg.Done()
		}(l, k)
	}

	wg.Wait()

	return multiErrors
}

func fetchTerraformData(username, groupname string, db *mongodb.MongoDB, identifiers []string) (*terraformData, error) {
	// fetch jaccount from username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	// fetch jGroup from group slug name
	group, err := modelhelper.GetGroup(groupname)
	if err != nil {
		return nil, err
	}

	// fetch jUser from username
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	// validate if username belongs to groupnam
	selector := modelhelper.Selector{
		"targetId": account.Id,
		"sourceId": group.Id,
		"as": bson.M{
			"$in": []string{"member"},
		},
	}

	count, err := modelhelper.RelationshipCount(selector)
	if err != nil || count == 0 {
		return nil, fmt.Errorf("username '%s' does not belong to group '%s'", username, groupname)
	}

	// 2- fetch credential from identifiers via args
	credentials, err := modelhelper.GetCredentialsFromIdentifiers(identifiers...)
	if err != nil {
		return nil, err
	}

	// 3- count relationship with credential id and jaccount id as user or
	// owner. Any non valid credentials will be discarded
	validKeys := make(map[string]string, 0)

	for _, cred := range credentials {
		selector := modelhelper.Selector{
			"targetId": cred.Id,
			"sourceId": bson.M{
				"$in": []bson.ObjectId{account.Id, group.Id},
			},
			"as": bson.M{
				"$in": []string{"owner", "user"},
			},
		}

		count, err := modelhelper.RelationshipCount(selector)
		if err != nil || count == 0 {
			// we return for any not validated identifier key.
			return nil, fmt.Errorf("credential with identifier '%s' is not validated", cred.Identifier)
		}

		validKeys[cred.Identifier] = cred.Provider
	}

	// 4- fetch credentialdata with identifier
	validIdentifiers := make([]string, 0)
	for pKey := range validKeys {
		validIdentifiers = append(identifiers, pKey)
	}

	credentialData, err := modelhelper.GetCredentialDatasFromIdentifiers(validIdentifiers...)
	if err != nil {
		return nil, err
	}

	// 5- return list of keys. We only support aws for now
	data := &terraformData{
		Account: account,
		Group:   group,
		User:    user,
		Creds:   make([]*terraformCredential, 0),
	}

	for _, c := range credentialData {
		provider, ok := validKeys[c.Identifier]
		if !ok {
			return nil, fmt.Errorf("provider is not found for identifer: %s", c.Identifier)
		}
		// for now we only support aws
		if provider != "aws" {
			continue
		}

		cred := &terraformCredential{
			Provider:   provider,
			Identifier: c.Identifier,
		}

		if err := mapstructure.Decode(c.Meta, &cred.Data); err != nil {
			return nil, err
		}

		data.Creds = append(data.Creds, cred)
	}

	return data, nil
}

// isVariable checkes whether the given string is a template variable, such as:
// "${var.region}"
func isVariable(v string) bool {
	return v[0] == '$'
}

// parseAccountID parses an AWS arn string to get the Account ID
func parseAccountID(arn string) (string, error) {
	// example arn string: "arn:aws:iam::213456789:user/username"
	// returns: 213456789.
	splitted := strings.Split(strings.TrimPrefix(arn, "arn:aws:iam::"), ":")
	if len(splitted) != 2 {
		return "", fmt.Errorf("Couldn't parse arn string: %s", arn)
	}

	return splitted[0], nil
}

// flattenValues converts the values of a map[string][]string to a []string slice.
func flattenValues(kv map[string][]string) []string {
	values := []string{}

	for _, val := range kv {
		values = append(values, val...)
	}

	return values
}
