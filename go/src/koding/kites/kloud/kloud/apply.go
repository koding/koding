package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
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

func (k *Kloud) Apply(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformKloudRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.TerraformContext == "" {
		return nil, NewError(ErrTerraformContextIsMissing)
	}

	if len(args.PublicKeys) == 0 {
		return nil, errors.New("publicKeys are not passed")
	}

	if len(args.MachineIds) == 0 {
		return nil, errors.New("machine ids are not passed")
	}

	if len(args.MachineIds) != len(args.PublicKeys) {
		return nil, errors.New("machineIds and publicKeys do not match")
	}

	ctx := request.NewContext(context.Background(), r)
	ctx = k.ContextCreator(ctx)

	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	machines, err := fetchMachines(ctx, args.MachineIds...)
	if err != nil {
		return nil, err
	}

	creds, err := fetchCredentials(r.Username, sess.DB, args.PublicKeys)
	if err != nil {
		return nil, err
	}

	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	args.TerraformContext = appendVariables(args.TerraformContext, creds)
	state, err := tfKite.Apply(args.TerraformContext)
	if err != nil {
		return nil, err
	}

	region, err := regionFromHCL(args.TerraformContext)
	if err != nil {
		return nil, err
	}

	output, err := machinesFromState(state)
	if err != nil {
		return nil, err
	}
	output.AppendRegion(region)

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
		terraformMachine, err := data.Label(machine.Label)
		if err != nil {
			return fmt.Errorf("machine label '%s' doesn't exist in terraform output", machine.Label)
		}

		storageSize, err := strconv.Atoi(terraformMachine.Attributes["root_block_device.0.volume_size"])
		if err != nil {
			return err
		}

		if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				machine.Id,
				bson.M{"$set": bson.M{
					"provider":          terraformMachine.Provider,
					"meta.region":       terraformMachine.Region,
					"ipAddress":         terraformMachine.Attributes["public_ip"],
					"meta.instanceId":   terraformMachine.Attributes["id"],
					"meta.instanceType": terraformMachine.Attributes["instance_type"],
					"meta.source_ami":   terraformMachine.Attributes["ami"],
					"meta.storage_size": storageSize,
				}},
			)
		}); err != nil {
			return err
		}
	}

	return nil
}
