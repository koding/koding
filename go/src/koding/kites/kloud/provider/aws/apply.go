package awsprovider

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/stackstate"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

// Apply
func (s *Stack) Apply(ctx context.Context) (interface{}, error) {
	var arg kloud.ApplyRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	stack, err := modelhelper.GetComputeStack(arg.StackID)
	if err != nil {
		return nil, err
	}

	if stack.State().InProgress() {
		return nil, fmt.Errorf("State is currently %s. Please try again later", stack.State())
	}

	if arg.Destroy {
		s.Eventer.Push(&eventer.Event{
			Message: s.Req.Method + " started",
			Status:  machinestate.Terminating,
		})
	} else {
		s.Eventer.Push(&eventer.Event{
			Message: s.Req.Method + " started",
			Status:  machinestate.Building,
		})
	}

	go func() {
		finalEvent := &eventer.Event{
			Message:    s.Req.Method + " finished",
			Status:     machinestate.Running,
			Percentage: 100,
		}

		start := time.Now()

		var err error
		if arg.Destroy {
			modelhelper.SetStackState(arg.StackID, "Stack destroying started",
				stackstate.Destroying)

			s.Log.New(arg.StackID).Info("======> %s (destroy) started <======",
				strings.ToUpper(s.Req.Method))
			finalEvent.Status = machinestate.Terminated
			err = s.destroy(ctx, s.Req.Username, arg.GroupName, arg.StackID)
		} else {
			modelhelper.SetStackState(arg.StackID, "Stack building started", stackstate.Building)

			s.Log.New(arg.StackID).Info("======> %s started <======", strings.ToUpper(s.Req.Method))
			err = s.apply(ctx, s.Req.Username, arg.GroupName, arg.StackID)
			if err != nil {
				modelhelper.SetStackState(arg.StackID, "Stack building failed",
					stackstate.NotInitialized)
				finalEvent.Status = machinestate.NotInitialized
			} else {
				modelhelper.SetStackState(arg.StackID, "Stack building finished",
					stackstate.Initialized)
			}

		}

		if err != nil {
			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			s.Log.New(arg.StackID).Error("%s error: %s", s.Req.Method, err)

			finalEvent.Error = err.Error()
			s.Log.New(arg.StackID).Error("======> %s finished with error (time: %s): '%s' <======",
				strings.ToUpper(s.Req.Method), time.Since(start), err.Error())
		} else {
			s.Log.New(arg.StackID).Info("======> %s finished (time: %s) <======",
				strings.ToUpper(s.Req.Method), time.Since(start))
		}

		s.Eventer.Push(finalEvent)
	}()

	return kloud.ControlResult{
		EventId: s.Eventer.ID(),
	}, nil
}

func (s *Stack) destroy(ctx context.Context, username, groupname, stackID string) error {
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

	if err := s.Builder.BuildStack(stackID); err != nil {
		return err
	}

	if err := s.Builder.BuildMachines(ctx); err != nil {
		return err
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	credIDs := stackplan.FlattenValues(s.Builder.Stack.Credentials)

	s.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), username)

	if err := s.Builder.BuildCredentials(req.Method, username, groupname, credIDs); err != nil {
		return err
	}

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)
	s.Log.Debug("Connection to Terraformer")

	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	s.Log.Debug("Building template")

	if err := s.Builder.BuildTemplate(s.Builder.Stack.Template); err != nil {
		return err
	}

	s.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")

	for _, cred := range s.Builder.Credentials {
		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		meta := cred.Meta.(*AwsMeta)
		if meta.Region == "" {
			return fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		if err := s.SetAwsRegion(meta.Region); err != nil {
			return err
		}
	}

	if _, err := s.InjectAWSData(ctx, username); err != nil {
		return err
	}

	out, err := s.Builder.Template.JsonOutput()
	if err != nil {
		return err
	}

	s.Builder.Stack.Template = out

	tfReq := &tf.TerraformRequest{
		Content:   s.Builder.Stack.Template,
		ContentID: username + "-" + stackID,
		Variables: nil,
	}

	s.Log.Debug("Calling terraform.destroy method with context:")
	s.Log.Debug("%+v", tfReq)

	_, err = tfKite.Destroy(tfReq)
	if err != nil {
		return err
	}

	for _, m := range s.Builder.Machines {
		if err := modelhelper.DeleteMachine(m.ObjectId); err != nil {
			return err
		}
	}

	return modelhelper.DeleteComputeStack(stackID)
}

func (s *Stack) apply(ctx context.Context, username, groupname, stackID string) error {
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

	if err := s.Builder.BuildStack(stackID); err != nil {
		return err
	}

	if err := s.Builder.BuildMachines(ctx); err != nil {
		return err
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	credIDs := stackplan.FlattenValues(s.Builder.Stack.Credentials)

	s.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), username)

	if err := s.Builder.BuildCredentials(req.Method, username, groupname, credIDs); err != nil {
		return err
	}

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)
	s.Log.Debug("Connection to Terraformer")

	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	s.Log.Debug("Building template")

	if err := s.Builder.BuildTemplate(s.Builder.Stack.Template); err != nil {
		return err
	}

	s.Log.Debug("Stack template before injecting Koding data:")
	s.Log.Debug("%s", s.Builder.Template)

	s.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")

	var region string
	for _, cred := range s.Builder.Credentials {
		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		meta := cred.Meta.(*AwsMeta)
		if meta.Region == "" {
			return fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		// check if this a second round and it's using a different region, we
		// shouldn't allow it.
		if region != "" && region != meta.Region {
			return fmt.Errorf("multiple credentials with multiple regions detected: %s and %s. Aborting",
				region, meta.Region)
		}

		region = meta.Region

		if err := s.SetAwsRegion(region); err != nil {
			return err
		}
	}

	kiteIDs, err := s.InjectAWSData(ctx, username)
	if err != nil {
		return err
	}

	out, err := s.Builder.Template.JsonOutput()
	if err != nil {
		return err
	}

	s.Builder.Stack.Template = out

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

	tfReq := &tf.TerraformRequest{
		Content:   s.Builder.Stack.Template,
		ContentID: username + "-" + stackID,
		Variables: nil,
	}
	s.Log.Debug("Final stack template. Calling terraform.apply method:")
	s.Log.Debug("%+v", tfReq)

	state, err := tfKite.Apply(tfReq)
	if err != nil {
		close(done)
		return err
	}

	fmt.Printf("state = %+v\n", state)

	close(done)

	ev.Push(&eventer.Event{
		Message:    "Checking VM connections",
		Percentage: 70,
		Status:     machinestate.Building,
	})

	if len(kiteIDs) != 0 {
		s.Log.Debug("Checking total '%d' klients", len(kiteIDs))
		if err := stackplan.CheckKlients(ctx, kiteIDs); err != nil {
			return err
		}
	}

	output, err := stackplan.MachinesFromState(state)
	if err != nil {
		return err
	}

	s.Log.Debug("Machines from state: %+v", output)
	s.Log.Debug("Build region: %+v", region)

	output.AppendRegion(region)

	if len(kiteIDs) != 0 {
		s.Log.Debug("Build data kiteIDS: %+v", kiteIDs)
		output.AppendQueryString(kiteIDs)
	}

	d, err := json.MarshalIndent(output, "", " ")
	if err != nil {
		return err
	}

	s.Log.Debug("Updated machines\n%s", string(d))
	s.Log.Debug("Updating and syncing terraform output to jMachine documents")

	ev.Push(&eventer.Event{
		Message:    "Updating machine settings",
		Percentage: 90,
		Status:     machinestate.Building,
	})

	return updateMachines(ctx, output, s.Builder.Machines)
}

func updateMachines(ctx context.Context, data *stackplan.Machines, jMachines []*models.Machine) error {
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

		switch tf.Provider {
		case "aws":
			if err := updateAWS(ctx, tf, machine.ObjectId); err != nil {
				return err
			}
		case "vagrantkite":
			if err := updateVagrantKite(ctx, tf, machine.ObjectId); err != nil {
				return err
			}
		}
	}

	return nil
}

func updateAWS(ctx context.Context, tf stackplan.Machine, machineId bson.ObjectId) error {
	size, err := strconv.Atoi(tf.Attributes["root_block_device.0.volume_size"])
	if err != nil {
		return err
	}

	return modelhelper.UpdateMachine(machineId, bson.M{"$set": bson.M{
		"provider":           tf.Provider,
		"meta.region":        tf.Region,
		"queryString":        tf.QueryString,
		"ipAddress":          tf.Attributes["public_ip"],
		"meta.instanceId":    tf.Attributes["id"],
		"meta.instance_type": tf.Attributes["instance_type"],
		"meta.source_ami":    tf.Attributes["ami"],
		"meta.storage_size":  size,
		"status.state":       machinestate.Running.String(),
		"status.modifiedAt":  time.Now().UTC(),
		"status.reason":      "Created with kloud.apply",
	}})
}

// TODO(rjeczalik): move to provider/vagrant
func updateVagrantKite(ctx context.Context, tf stackplan.Machine, machineId bson.ObjectId) error {
	return modelhelper.UpdateMachine(machineId, bson.M{"$set": bson.M{
		"provider":            tf.Provider,
		"queryString":         tf.QueryString,
		"ipAddress":           tf.Attributes["ipAddress"],
		"meta.filePath":       tf.Attributes["filePath"],
		"meta.memory":         tf.Attributes["memory"],
		"meta.cpus":           tf.Attributes["cpus"],
		"meta.box":            tf.Attributes["box"],
		"meta.hostname":       tf.Attributes["hostname"],
		"meta.klientHostURL":  tf.Attributes["klientHostURL"],
		"meta.klientGuestURL": tf.Attributes["klientGuestURL"],
		"status.state":        machinestate.Running.String(),
		"status.modifiedAt":   time.Now().UTC(),
		"status.reason":       "Created with kloud.apply",
	}})
}
