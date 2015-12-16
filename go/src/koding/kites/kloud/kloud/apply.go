package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stackstate"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"github.com/koding/kite"
	"golang.org/x/net/context"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// Stack is struct that contains all necessary information Apply needs to
// perform successfully.
type Stack struct {
	// jMachine ids
	Machines []string

	// jCredential provider to identifiers
	Credentials map[string][]string

	// Terraform template
	Template string
}

type TerraformApplyRequest struct {
	StackId string `json:"stackId"`

	GroupName string `json:"groupName"`

	// Destroy, if enabled, destroys the terraform tempalte associated with the
	// given StackId.
	Destroy bool
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

	if args.GroupName == "" {
		return nil, errors.New("group name is not passed")
	}

	// create context with the given request
	ctx := request.NewContext(context.Background(), r)
	ctx = publickeys.NewContext(ctx, k.PublicKeys)
	ctx = k.ContextCreator(ctx)

	// create eventer and also add it to the context
	eventId := r.Method + "-" + args.StackId
	ev := k.NewEventer(eventId)

	if args.Destroy {
		ev.Push(&eventer.Event{
			Message: r.Method + " started",
			Status:  machinestate.Terminating,
		})

	} else {
		ev.Push(&eventer.Event{
			Message: r.Method + " started",
			Status:  machinestate.Building,
		})
	}

	ctx = eventer.NewContext(ctx, ev)

	go func() {
		finalEvent := &eventer.Event{
			Message:    r.Method + " finished",
			Status:     machinestate.Running,
			Percentage: 100,
		}

		start := time.Now()

		var err error
		if args.Destroy {
			modelhelper.SetStackState(args.StackId, "Stack destroying started", stackstate.Destroying)

			k.Log.New(args.StackId).Info("======> %s (destroy) started <======", strings.ToUpper(r.Method))
			finalEvent.Status = machinestate.Terminated
			err = destroy(ctx, r.Username, args.GroupName, args.StackId)
		} else {
			modelhelper.SetStackState(args.StackId, "Stack building started", stackstate.Building)

			k.Log.New(args.StackId).Info("======> %s started <======", strings.ToUpper(r.Method))
			err = apply(ctx, r.Username, args.GroupName, args.StackId)
			if err != nil {
				modelhelper.SetStackState(args.StackId, "Stack building failed", stackstate.NotInitialized)
				finalEvent.Status = machinestate.NotInitialized
			} else {
				modelhelper.SetStackState(args.StackId, "Stack building finished", stackstate.Initialized)
			}

		}

		if err != nil {
			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			k.Log.New(args.StackId).Error("%s error: %s", r.Method, err)

			finalEvent.Error = err.Error()
			k.Log.New(args.StackId).Error("======> %s finished with error (time: %s): '%s' <======",
				strings.ToUpper(r.Method), time.Since(start), err.Error())
		} else {
			k.Log.New(args.StackId).Info("======> %s finished (time: %s) <======",
				strings.ToUpper(r.Method), time.Since(start))
		}

		ev.Push(finalEvent)
	}()

	return ControlResult{
		EventId: eventId,
	}, nil
}

func destroy(ctx context.Context, username, groupname, stackId string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return errors.New("eventer context is not passed")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not passed")
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Building,
	})

	stack, err := fetchStack(stackId)
	if err != nil {
		return err
	}

	sess.Log.Debug("Validating '%d' machines from user '%s'", len(stack.Machines), username)
	machines, err := fetchMachines(ctx, stack.Machines...)
	if err != nil {
		return err
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	sess.Log.Debug("Fetching '%d' credentials from user '%s'", len(stack.Credentials), username)
	data, err := fetchTerraformData(req.Method, username, groupname, sess.DB, flattenValues(stack.Credentials))
	if err != nil {
		return err
	}

	sess.Log.Debug("Connection to Terraformer")
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	sess.Log.Debug("Parsing the template")
	template, err := newTerraformTemplate(stack.Template)
	if err != nil {
		return err
	}

	sess.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")
	for _, cred := range data.Creds {
		if err := template.injectCustomVariables(cred.Provider, cred.Data); err != nil {
			return err
		}

		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		region, ok := cred.Data["region"]
		if !ok {
			return fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		if err := template.setAwsRegion(region); err != nil {
			return err
		}
	}

	buildData, err := injectKodingData(ctx, template, username, data)
	if err != nil {
		return err
	}
	stack.Template = buildData.Template

	sess.Log.Debug("Calling terraform.destroy method with context:")
	sess.Log.Debug(stack.Template)
	_, err = tfKite.Destroy(&tf.TerraformRequest{
		Content:   stack.Template,
		ContentID: username + "-" + stackId,
		Variables: nil,
	})
	if err != nil {
		return err
	}

	for _, m := range machines {
		if err := modelhelper.DeleteMachine(m.ObjectId); err != nil {
			return err
		}
	}

	return modelhelper.DeleteComputeStack(stackId)
}

func apply(ctx context.Context, username, groupname, stackId string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return errors.New("eventer context is not passed")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("internal server error (err: session context is not available)")
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Building,
	})

	stack, err := fetchStack(stackId)
	if err != nil {
		return err
	}

	sess.Log.Debug("Fetching and validating '%d' machines from user '%s'", len(stack.Machines), username)
	machines, err := fetchMachines(ctx, stack.Machines...)
	if err != nil {
		return err
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	sess.Log.Debug("Fetching '%d' credentials from user '%s'", len(stack.Credentials), username)
	data, err := fetchTerraformData(req.Method, username, groupname, sess.DB, flattenValues(stack.Credentials))
	if err != nil {
		return err
	}

	sess.Log.Debug("Connection to Terraformer")
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	sess.Log.Debug("Parsing the template")
	sess.Log.Debug("%s", stack.Template)
	template, err := newTerraformTemplate(stack.Template)
	if err != nil {
		return err
	}

	sess.Log.Debug("Stack template before injecting Koding data:")
	sess.Log.Debug("%s", template)

	sess.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")

	var region string
	for _, cred := range data.Creds {
		sess.Log.Debug("Appending %s provider variables", cred.Provider)
		if err := template.injectCustomVariables(cred.Provider, cred.Data); err != nil {
			return err
		}

		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		credRegion, ok := cred.Data["region"]
		if !ok {
			return fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		// check if this a second round and it's using a different region, we
		// shouldn't allow it.
		if region != "" && region != credRegion {
			return fmt.Errorf("multiple credentials with multiple regions detected: %s and %s. Aborting",
				region, credRegion)
		}

		region = credRegion

		if err := template.setAwsRegion(region); err != nil {
			return err
		}
	}

	buildData, err := injectKodingData(ctx, template, username, data)
	if err != nil {
		return err
	}
	stack.Template = buildData.Template

	done := make(chan struct{})

	// because apply can last long, we are going to increment the eventer's
	// percentage as long as we build automatically.
	go func() {
		ticker := time.NewTicker(time.Second * 5)
		start := 45

		for {
			select {
			case <-done:
				return
			case <-ticker.C:
				if start < 70 {
					start += 5
				}

				ev.Push(&eventer.Event{
					Message:    "Building stack resources",
					Percentage: start,
					Status:     machinestate.Building,
				})
			}
		}
	}()

	sess.Log.Debug("Final stack template. Calling terraform.apply method:")
	sess.Log.Debug(stack.Template)

	state, err := tfKite.Apply(&tf.TerraformRequest{
		Content:   stack.Template,
		ContentID: username + "-" + stackId,
		Variables: nil,
	})
	if err != nil {
		close(done)
		return err
	}

	close(done)

	ev.Push(&eventer.Event{
		Message:    "Checking VM connections",
		Percentage: 70,
		Status:     machinestate.Building,
	})

	sess.Log.Debug("Checking total '%d' klients", len(buildData.KiteIds))
	if err := checkKlients(ctx, buildData.KiteIds); err != nil {
		return err
	}

	output, err := machinesFromState(state)
	if err != nil {
		return err
	}

	sess.Log.Debug("Machines from state: %+v", output)
	sess.Log.Debug("Build region: %+v", region)
	sess.Log.Debug("Build data kiteIDS: %+v", buildData.KiteIds)
	output.AppendRegion(region)
	output.AppendQueryString(buildData.KiteIds)

	d, err := json.MarshalIndent(output, "", " ")
	if err != nil {
		return err
	}
	sess.Log.Debug("Updated machines\n%s", string(d))

	sess.Log.Debug("Updating and syncing terraform output to jMachine documents")
	ev.Push(&eventer.Event{
		Message:    "Updating machine settings",
		Percentage: 90,
		Status:     machinestate.Building,
	})
	return updateMachines(ctx, output, machines)
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

	credentials := make(map[string][]string, 0)

	// first copy admin/group based credentials
	for k, v := range stackTemplate.Credentials {
		credentials[k] = v
	}

	// copy user based credentials
	for k, v := range computeStack.Credentials {
		// however don't override anything the admin already added
		if _, ok := credentials[k]; !ok {
			credentials[k] = v
		}
	}

	return &Stack{
		Machines:    machineIds,
		Credentials: credentials,
		Template:    stackTemplate.Template.Content,
	}, nil
}

func fetchMachines(ctx context.Context, ids ...string) ([]*models.Machine, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	mongodbIds := make([]bson.ObjectId, len(ids))
	for i, id := range ids {
		mongodbIds[i] = bson.ObjectIdHex(id)
	}

	machines := make([]*models.Machine, 0)
	if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": mongodbIds}}).All(&machines)
	}); err != nil {
		return nil, err
	}

	validUsers := make(map[string]models.MachineUser, 0)
	validMachines := make(map[string]*models.Machine, 0)

	for _, machine := range machines {
		// machines with empty users are supposed to allowed by default
		// (gokmen)
		if machine.Users == nil || len(machine.Users) == 0 {
			validMachines[machine.ObjectId.Hex()] = machine
			continue
		}

		// for others we need to be sure they are valid
		// TODO(arslan): add custom type with custom methods for type
		// []*Machineuser
		for _, user := range machine.Users {
			// we only going to select users that are allowed
			if user.Sudo && user.Owner {
				validUsers[user.Id.Hex()] = user
			} else {
				// return early, we don't tolerate nonvalid inputs to apply
				return nil, fmt.Errorf("machine '%s' is not valid. Aborting apply",
					machine.ObjectId.Hex())
			}
		}
	}

	allowedIds := make([]bson.ObjectId, len(validUsers))
	for _, user := range validUsers {
		allowedIds = append(allowedIds, user.Id)
	}

	users, err := modelhelper.GetUsersById(allowedIds...)
	if err != nil {
		return nil, err
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not passed")
	}

	// we're going to need this helper function
	// TODO(arslan): as for []*Machineuser we should have custom type for
	// []*Machines to have helper methods of it.
	machineFromUserId := func(id bson.ObjectId) *models.Machine {
		for _, machine := range machines {
			for _, user := range machine.Users {
				if user.Id.Hex() == id.Hex() {
					return machine
				}
			}
		}
		return nil
	}

	// now check if the requested user is inside the allowed users list
	for _, u := range users {
		if u.Name != req.Username {
			continue
		}

		if m := machineFromUserId(u.ObjectId); m != nil {
			validMachines[m.ObjectId.Hex()] = m
		}
	}

	if len(validMachines) == 0 {
		return nil, fmt.Errorf("no valid machines found for the user: %s", req.Username)
	}

	finalMachines := make([]*models.Machine, 0)
	for _, m := range validMachines {
		finalMachines = append(finalMachines, m)
	}

	return finalMachines, nil
}

func updateMachines(ctx context.Context, data *Machines, jMachines []*models.Machine) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	for _, machine := range jMachines {
		label := machine.Label
		if l, ok := machine.Meta["assignedLabel"]; ok {
			if ll, ok := l.(string); ok {
				label = ll
			}
		}

		tf, err := data.WithLabel(label)
		if err != nil {
			return fmt.Errorf("machine label '%s' doesn't exist in terraform output", label)
		}

		size, err := strconv.Atoi(tf.Attributes["root_block_device.0.volume_size"])
		if err != nil {
			return err
		}

		ipAddress := tf.Attributes["public_ip"]

		if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				machine.ObjectId,
				bson.M{"$set": bson.M{
					"provider":          tf.Provider,
					"meta.region":       tf.Region,
					"queryString":       tf.QueryString,
					"ipAddress":         ipAddress,
					"meta.instanceId":   tf.Attributes["id"],
					"meta.instanceType": tf.Attributes["instance_type"],
					"meta.source_ami":   tf.Attributes["ami"],
					"meta.storage_size": size,
					"status.state":      machinestate.Running.String(),
					"status.modifiedAt": time.Now().UTC(),
					"status.reason":     "Created with kloud.apply",
				}},
			)
		}); err != nil {
			return err
		}
	}

	return nil
}
