package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/provider/generic"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"
	"strconv"
	"strings"
	"time"

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

	// create context with the given request
	ctx := request.NewContext(context.Background(), r)
	ctx = publickeys.NewContext(ctx, k.PublicKeys)
	ctx = k.ContextCreator(ctx)

	// create eventer and also add it to the context
	eventId := r.Method + "-" + args.StackId
	ev := k.NewEventer(eventId)
	ev.Push(&eventer.Event{
		Message: r.Method + " started",
		Status:  machinestate.Building,
	})
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
			k.Log.Info("[%s] ======> %s (destroy) started <======", args.StackId, strings.ToUpper(r.Method))
			finalEvent.Status = machinestate.Terminated
			err = destroy(ctx, r.Username, args.StackId)
		} else {
			k.Log.Info("[%s] ======> %s started <======", args.StackId, strings.ToUpper(r.Method))
			err = apply(ctx, r.Username, args.StackId)
			if err != nil {
				finalEvent.Status = machinestate.NotInitialized
			}
		}

		if err != nil {
			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			k.Log.Error("[%s] %s error: %s", args.StackId, r.Method, err)
			finalEvent.Error = strings.ToTitle(r.Method) + " failed. Please contact support."
			// however, eventerErr is an error we want to pass explicitly to
			// the client side
			if eventerErr, ok := err.(*EventerError); ok {
				finalEvent.Error = eventerErr.Error()
			}
		}

		k.Log.Info("[%s] ======> %s finished (time: %s) <======",
			args.StackId, strings.ToUpper(r.Method), time.Since(start))

		ev.Push(finalEvent)
	}()

	return ControlResult{
		EventId: eventId,
	}, nil
}

func destroy(ctx context.Context, username, stackId string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return errors.New("eventer context is not passed")
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
	if _, err := fetchMachines(ctx, stack.Machines...); err != nil {
		return err
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	sess.Log.Debug("Fetching '%d' credentials from user '%s'", len(stack.PublicKeys), username)
	creds, err := fetchCredentials(username, sess.DB, stack.PublicKeys)
	if err != nil {
		return err
	}

	sess.Log.Debug("Connection to Terraformer")
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	for _, cred := range creds.Creds {
		stack.Template, err = cred.appendAWSVariable(stack.Template)
		if err != nil {
			return err
		}
	}

	sess.Log.Debug("Calling terraform.destroy method with context:")
	sess.Log.Debug(stack.Template)
	state, err := tfKite.Destroy(&tf.TerraformRequest{
		Content:   stack.Template,
		ContentID: username + "-" + stackId,
		Variables: nil,
	})
	if err != nil {
		return err
	}

	fmt.Printf("state = %+v\n", state)
	return nil
}

func apply(ctx context.Context, username, stackId string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return errors.New("eventer context is not passed")
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

	sess.Log.Debug("Fetching '%d' credentials from user '%s'", len(stack.PublicKeys), username)
	creds, err := fetchCredentials(username, sess.DB, stack.PublicKeys)
	if err != nil {
		return err
	}

	sess.Log.Debug("Connection to Terraformer")
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	for _, cred := range creds.Creds {
		stack.Template, err = cred.appendAWSVariable(stack.Template)
		if err != nil {
			return err
		}
	}

	buildData, err := injectKodingData(ctx, stack.Template, username, creds)
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
					Message:    "Building stack",
					Percentage: start,
					Status:     machinestate.Building,
				})
			}
		}
	}()

	sess.Log.Debug("Calling terraform.apply method with context:")
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
		Message:    "Creating artifact",
		Percentage: 70,
		Status:     machinestate.Building,
	})

	output, err := machinesFromState(state)
	if err != nil {
		return err
	}
	output.AppendRegion(buildData.Region)
	output.AppendQueryString(buildData.KiteIds)

	ev.Push(&eventer.Event{
		Message:    "Updating domains and machine settings",
		Percentage: 80,
		Status:     machinestate.Building,
	})

	sess.Log.Debug("Updating and syncing terraform output to jMachine documents")
	if err := updateMachines(ctx, output, machines); err != nil {
		return err
	}

	d, err := json.MarshalIndent(output, "", " ")
	if err != nil {
		return err
	}

	fmt.Printf(string(d))

	ev.Push(&eventer.Event{
		Message:    "Checking klient connections",
		Percentage: 90,
		Status:     machinestate.Building,
	})

	return checkKlients(ctx, buildData.KiteIds)
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

	allowedUsers, err := modelhelper.GetUsersById(allowedIds...)
	if err != nil {
		return nil, err
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not passed")
	}

	// now check if the requested user is inside the allowed users list
	for _, u := range allowedUsers {
		if u.Name == req.Username {
			return machines, nil
		}
	}

	return nil, fmt.Errorf("machine is only allowed for users: %v. But have: %s", allowedUsers, req.Username)
}

func updateMachines(ctx context.Context, data *Machines, jMachines []*generic.Machine) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not passed")
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

		ipAddress := tf.Attributes["public_ip"]

		// create domains
		for _, m := range jMachines {
			if err := sess.DNSClient.Validate(m.Domain, req.Username); err != nil {
				sess.Log.Error("couldn't validate machine domain: %s", err.Error())
			}

			if err := sess.DNSClient.Upsert(m.Domain, ipAddress); err != nil {
				sess.Log.Error("couldn't update machine domain: %s", err.Error())
			}
		}

		if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				machine.Id,
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
