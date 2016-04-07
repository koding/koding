package awsprovider

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
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

// Apply builds and expands compute stack template for the given ID and
// sends an apply request to terraformer.
//
// When destroy=false, building and expanding the stack prior to
// terraformer request is done asynchronously, and the result of
// that operation is communicated back with eventer.
//
// When destroy=true, fetching machines from DB is done synchronously, as
// as soon as Apply method returns, allowed user list for each machine
// is zeroed, which could make the destroy oepration to fail - we
// first build machines and rest of the destroy is perfomed asynchronously.
//
// TODO(rjeczalik): move to *provider.BaseStack
func (s *Stack) Apply(ctx context.Context) (interface{}, error) {
	var arg kloud.ApplyRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	if err := s.Builder.BuildStack(arg.StackID); err != nil {
		return nil, err
	}

	if state := s.Builder.Stack.Stack.State(); state.InProgress() {
		return nil, fmt.Errorf("State is currently %s. Please try again later", state)
	}

	if rt, ok := kloud.RequestTraceFromContext(ctx); ok {
		rt.Hijack()
	}

	var err error
	if arg.Destroy {
		err = s.destroy(ctx, &arg)
	} else {
		err = s.apply(ctx, &arg)
	}

	if err != nil {
		return nil, err
	}

	return kloud.ControlResult{
		EventId: s.Eventer.ID(),
	}, nil
}

func (s *Stack) apply(ctx context.Context, req *kloud.ApplyRequest) error {
	log := s.Log.New(req.StackID)

	s.Eventer.Push(&eventer.Event{
		Message: s.Req.Method + " started",
		Status:  machinestate.Building,
	})

	go func() {
		finalEvent := &eventer.Event{
			Message:    s.Req.Method + " finished",
			Status:     machinestate.Running,
			Percentage: 100,
		}

		start := time.Now()

		modelhelper.SetStackState(req.StackID, "Stack building started", stackstate.Building)
		log.Info("======> %s started <======", strings.ToUpper(s.Req.Method))

		if err := s.applyAsync(ctx, req); err != nil {
			modelhelper.SetStackState(req.StackID, "Stack building failed", stackstate.NotInitialized)
			finalEvent.Status = machinestate.NotInitialized

			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			finalEvent.Error = err.Error()
			log.Error("======> %s finished with error (time: %s): '%s' <======",
				strings.ToUpper(s.Req.Method), time.Since(start), err.Error())
		} else {
			modelhelper.SetStackState(req.StackID, "Stack building finished", stackstate.Initialized)
			log.Info("======> %s finished (time: %s) <======", strings.ToUpper(s.Req.Method), time.Since(start))
		}

		s.Eventer.Push(finalEvent)
	}()

	return nil
}

func (s *Stack) destroy(ctx context.Context, req *kloud.ApplyRequest) error {
	log := s.Log.New(req.StackID)

	s.Eventer.Push(&eventer.Event{
		Message: s.Req.Method + " started",
		Status:  machinestate.Terminating,
	})

	start := time.Now()

	modelhelper.SetStackState(req.StackID, "Stack destroying started", stackstate.Destroying)
	log.Info("======> %s (destroy) started <======", strings.ToUpper(s.Req.Method))

	s.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Terminating,
	})

	if err := s.Builder.BuildMachines(ctx); err != nil {
		return err
	}

	if err := s.Builder.Database.Detach(); err != nil {
		return err
	}

	// This part is done asynchronously.
	go func() {
		finalEvent := &eventer.Event{
			Message:    s.Req.Method + " finished",
			Percentage: 100,
			Status:     machinestate.Terminated,
		}

		err := s.destroyAsync(ctx, req)
		if err != nil {
			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			finalEvent.Error = err.Error()
			log.Error("======> %s finished with error (time: %s): '%s' <======",
				strings.ToUpper(s.Req.Method), time.Since(start), err)
		} else {
			log.Info("======> %s finished (time: %s) <======", strings.ToUpper(s.Req.Method), time.Since(start))
		}

		s.Eventer.Push(finalEvent)
	}()

	return nil
}

func (s *Stack) destroyAsync(ctx context.Context, req *kloud.ApplyRequest) error {
	if rt, ok := kloud.RequestTraceFromContext(ctx); ok {
		defer rt.Send()
	}

	s.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Terminating,
	})

	credIDs := stackplan.FlattenValues(s.Builder.Stack.Credentials)

	s.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), s.Req.Username)

	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, req.GroupName, credIDs); err != nil {
		return err
	}

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)
	s.Log.Debug("Connection to Terraformer")

	tfKite, err := terraformer.Connect(s.Session.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	contentID := req.GroupName + "-" + req.StackID
	s.Log.Debug("Building template %s", contentID)

	if err := s.Builder.BuildTemplate(s.Builder.Stack.Template, contentID); err != nil {
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

	if _, err := s.InjectAWSData(ctx, s.Req.Username, false); err != nil {
		return err
	}

	out, err := s.Builder.Template.JsonOutput()
	if err != nil {
		return err
	}

	s.Builder.Stack.Template = out

	tfReq := &tf.TerraformRequest{
		Content:   s.Builder.Stack.Template,
		ContentID: contentID,
		Variables: nil,
		TraceID:   s.TraceID,
	}

	s.Log.Debug("Calling terraform.destroy method with context:")
	s.Log.Debug("%+v", tfReq)

	_, err = tfKite.Destroy(tfReq)
	if err != nil {
		return err
	}

	return s.Builder.Database.Destroy()
}

func (s *Stack) applyAsync(ctx context.Context, req *kloud.ApplyRequest) error {
	if rt, ok := kloud.RequestTraceFromContext(ctx); ok {
		defer rt.Send()
	}

	s.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Building,
	})

	if err := s.Builder.BuildMachines(ctx); err != nil {
		return err
	}

	s.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	credIDs := stackplan.FlattenValues(s.Builder.Stack.Credentials)

	s.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), s.Req.Username)

	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, req.GroupName, credIDs); err != nil {
		return err
	}

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)
	s.Log.Debug("Connection to Terraformer")

	tfKite, err := terraformer.Connect(s.Session.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	contentID := req.GroupName + "-" + req.StackID
	s.Log.Debug("Building template: %s", contentID)

	if err := s.Builder.BuildTemplate(s.Builder.Stack.Template, contentID); err != nil {
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

	kiteIDs, err := s.InjectAWSData(ctx, s.Req.Username, true)
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

				s.Eventer.Push(&eventer.Event{
					Message:    "Building stack resources",
					Percentage: start,
					Status:     machinestate.Building,
				})
			}
		}
	}()

	tfReq := &tf.TerraformRequest{
		Content:   s.Builder.Stack.Template,
		ContentID: contentID,
		Variables: nil,
		TraceID:   s.TraceID,
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

	s.Eventer.Push(&eventer.Event{
		Message:    "Checking VM connections",
		Percentage: 70,
		Status:     machinestate.Building,
	})

	s.Log.Debug("Checking total '%d' klients", len(kiteIDs))
	urls, err := s.p.CheckKlients(ctx, kiteIDs)
	if err != nil {
		return err
	}

	output, err := s.p.MachinesFromState(state)
	if err != nil {
		return err
	}

	s.Log.Debug("Machines from state: %+v", output)
	s.Log.Debug("Build region: %+v", region)

	output.AppendRegion(region)
	output.AppendQueryString(kiteIDs)
	output.AppendRegisterURL(urls)

	d, err := json.MarshalIndent(output, "", " ")
	if err != nil {
		return err
	}

	s.Log.Debug("Updated machines\n%s", string(d))
	s.Log.Debug("Updating and syncing terraform output to jMachine documents")

	s.Eventer.Push(&eventer.Event{
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

		if tf.Provider == "aws" {
			if err := updateAWS(ctx, tf, machine.ObjectId); err != nil {
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
