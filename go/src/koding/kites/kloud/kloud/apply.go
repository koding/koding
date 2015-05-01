package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/provider/generic"
	"koding/kites/kloud/terraformer"
	"strconv"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/koding/kite"
)

// Stack is struct that contains all necessary information Apply needs to
// perform successfully.
type Stack struct {
	// jMachine ids
	Machines []string

	// jCredential public keys
	PublicKeys []string

	// Terraform template
	Template string
}

type TerraformApplyRequest struct {
	StackId string `json:"stackId"`
}

func (k *Kloud) Apply(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformApplyRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.StackId == "" {
		return nil, errors.New("stackId is not passed")
	}

	ctx := request.NewContext(context.Background(), r)
	ctx = k.ContextCreator(ctx)

	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	stack, err := fetchStack(args.StackId)
	if err != nil {
		return nil, err
	}

	k.Log.Debug("Fetching and validating '%d' machines from user '%s'", len(stack.Machines), r.Username)
	machines, err := fetchMachines(ctx, stack.Machines...)
	if err != nil {
		return nil, err
	}

	k.Log.Debug("Fetching '%d' credentials from user '%s'", len(stack.PublicKeys), r.Username)
	creds, err := fetchCredentials(r.Username, sess.DB, stack.PublicKeys)
	if err != nil {
		return nil, err
	}

	k.Log.Debug("Connection to Terraformer")
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	stack.Template = appendVariables(stack.Template, creds)
	k.Log.Debug("Calling terraform.apply method with context:")
	k.Log.Debug(stack.Template)

	state, err := tfKite.Apply(stack.Template)
	if err != nil {
		return nil, err
	}

	region, err := regionFromHCL(stack.Template)
	if err != nil {
		return nil, err
	}

	output, err := machinesFromState(state)
	if err != nil {
		return nil, err
	}
	output.AppendRegion(region)

	k.Log.Debug("Updating and syncing terraform output to jMachine documents")
	if err := updateMachines(ctx, output, machines); err != nil {
		return nil, err
	}

	d, err := json.MarshalIndent(output, "", " ")
	if err != nil {
		return nil, err
	}

	fmt.Printf(string(d))

	return nil, errors.New("not implemented yet")
}

func fetchStack(stackId string) (*Stack, error) {
	computeStack, err := modelhelper.GetComputeStack(stackId)
	if err != nil {
		return nil, err
	}

	stackTemplate, err := modelhelper.GetStackTemplate(computeStack.BaseStackId.Hex())
	if err != nil {
		return nil, err
	}

	machineIds := make([]string, len(computeStack.Machines))
	for i, m := range computeStack.Machines {
		machineIds[i] = m.Hex()
	}

	return &Stack{
		Machines:   machineIds,
		PublicKeys: stackTemplate.Credentials,
		Template:   stackTemplate.Template.Content,
	}, nil
}

func fetchMachines(ctx context.Context, ids ...string) ([]*generic.Machine, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	mongodbIds := make([]bson.ObjectId, len(ids))
	for i, id := range ids {
		mongodbIds[i] = bson.ObjectIdHex(id)
	}

	machines := make([]*generic.Machine, 0)
	if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": mongodbIds}}).All(&machines)
	}); err != nil {
		return nil, err
	}

	allowedIds := make([]bson.ObjectId, len(machines))

	for i, machine := range machines {
		for _, perm := range machine.Users {
			// we only going to fetch users that are allowed
			if perm.Sudo && perm.Owner {
				allowedIds[i] = perm.Id
			} else {
				return nil, fmt.Errorf("machine '%s' is not valid. Aborting apply", machine.Id.Hex())
			}
		}
	}

	var allowedUsers []*models.User
	if err := sess.DB.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": allowedIds}}).All(&allowedUsers)
	}); err != nil {
		return nil, fmt.Errorf("username lookup error: %v", err)
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not passed")
	}

	// validate users
	for _, u := range allowedUsers {
		if u.Name != req.Username {
			return nil, fmt.Errorf("machine is only allowed for user: %s. But have: %s", req.Username, u.Name)
		}
	}

	return machines, nil
}

func updateMachines(ctx context.Context, data *Machines, jMachines []*generic.Machine) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	for _, machine := range jMachines {
		tf, err := data.WithLabel(machine.Label)
		if err != nil {
			return fmt.Errorf("machine label '%s' doesn't exist in terraform output", machine.Label)
		}

		size, err := strconv.Atoi(tf.Attributes["root_block_device.0.volume_size"])
		if err != nil {
			return err
		}

		if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				machine.Id,
				bson.M{"$set": bson.M{
					"provider":          tf.Provider,
					"meta.region":       tf.Region,
					"ipAddress":         tf.Attributes["public_ip"],
					"meta.instanceId":   tf.Attributes["id"],
					"meta.instanceType": tf.Attributes["instance_type"],
					"meta.source_ami":   tf.Attributes["ami"],
					"meta.storage_size": size,
				}},
			)
		}); err != nil {
			return err
		}
	}

	return nil
}
