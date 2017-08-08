package provider

import (
	"fmt"
	"net"
	"net/url"
	"strings"
	"time"

	"gopkg.in/mgo.v2/bson"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	uuid "github.com/satori/go.uuid"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackstate"
	"koding/kites/kloud/terraformer"
	"koding/kites/kloud/utils/object"

	"golang.org/x/net/context"
)

// HandleApply builds and expands compute stack template for the given ID and
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
func (bs *BaseStack) HandleApply(ctx context.Context) (interface{}, error) {
	arg, ok := ctx.Value(stack.ApplyRequestKey).(*stack.ApplyRequest)
	if !ok {
		arg = &stack.ApplyRequest{}

		if err := bs.Req.Args.One().Unmarshal(arg); err != nil {
			return nil, err
		}
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	err := bs.Builder.BuildStack(arg.StackID, arg.Credentials)

	if err != nil && !(arg.Destroy && models.IsNotFound(err, "jStackTemplate")) {
		return nil, err
	}

	if state := bs.Builder.Stack.Stack.State(); state.InProgress() {
		return nil, fmt.Errorf("State is currently %s. Please try again later", state)
	}

	if rt, ok := stack.RequestTraceFromContext(ctx); ok {
		rt.Hijack()
	}

	bs.Arg = arg

	if arg.Destroy {
		err = bs.destroy(ctx, arg)
	} else {
		go bs.apply(ctx, arg)
	}

	if err != nil {
		return nil, err
	}

	return &stack.ControlResult{
		EventId: bs.Eventer.ID(),
	}, nil
}

func (bs *BaseStack) apply(ctx context.Context, req *stack.ApplyRequest) {
	log := bs.Log.New(req.StackID)

	bs.Eventer.Push(&eventer.Event{
		Message: bs.Req.Method + " started",
		Status:  machinestate.Building,
	})

	finalEvent := &eventer.Event{
		Message:    bs.Req.Method + " finished",
		Status:     machinestate.Running,
		Percentage: 100,
	}

	start := time.Now()

	modelhelper.SetStackState(req.StackID, "Stack building started", stackstate.Building)
	log.Info("======> %s started <======", strings.ToUpper(bs.Req.Method))

	var err error
	defer func() {
		if v := recover(); v != nil {
			if e, ok := v.(error); ok {
				err = e
			} else {
				err = fmt.Errorf("%v", v)
			}
		}

		if err != nil {
			modelhelper.SetStackState(req.StackID, "Stack building failed", stackstate.NotInitialized)
			finalEvent.Status = machinestate.NotInitialized

			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			finalEvent.Error = err.Error()
			log.Error("======> %s finished with error (time: %s): '%s' <======",
				strings.ToUpper(bs.Req.Method), time.Since(start), err.Error())
		} else {
			modelhelper.SetStackState(req.StackID, "Stack building finished", stackstate.Initialized)
			log.Info("======> %s finished (time: %s) <======", strings.ToUpper(bs.Req.Method), time.Since(start))
		}

		bs.Eventer.Push(finalEvent)
	}()

	err = bs.applyAsync(ctx, req)
}

func (bs *BaseStack) destroy(ctx context.Context, req *stack.ApplyRequest) error {
	log := bs.Log.New(req.StackID)

	bs.Eventer.Push(&eventer.Event{
		Message: bs.Req.Method + " started",
		Status:  machinestate.Terminating,
	})

	start := time.Now()

	modelhelper.SetStackState(req.StackID, "Stack destroying started", stackstate.Destroying)
	log.Info("======> %s (destroy) started <======", strings.ToUpper(bs.Req.Method))

	bs.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Terminating,
	})

	if err := bs.Builder.BuildMachines(ctx); err != nil {
		return err
	}

	if err := bs.Builder.Database.Detach(); err != nil {
		return err
	}

	// This part is done asynchronously.
	go func() {
		finalEvent := &eventer.Event{
			Message:    bs.Req.Method + " finished",
			Percentage: 100,
			Status:     machinestate.Terminated,
		}

		err := bs.destroyAsync(ctx, req)
		if err != nil {
			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			finalEvent.Error = err.Error()
			log.Error("======> %s finished with error (time: %s): '%s' <======",
				strings.ToUpper(bs.Req.Method), time.Since(start), err)
		} else {
			log.Info("======> %s finished (time: %s) <======", strings.ToUpper(bs.Req.Method), time.Since(start))
		}

		bs.Eventer.Push(finalEvent)
	}()

	return nil
}

func (bs *BaseStack) destroyAsync(ctx context.Context, req *stack.ApplyRequest) error {
	if rt, ok := stack.RequestTraceFromContext(ctx); ok {
		defer rt.Send()
	}

	bs.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Terminating,
	})

	credIDs := FlattenValues(bs.Builder.Stack.Credentials)

	bs.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), bs.Req.Username)

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, req.GroupName, credIDs); err != nil {
		return err
	}

	bs.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", bs.Builder.Koding, bs.Builder.Template)

	if bs.Builder.Stack.Stack.State() != stackstate.NotInitialized {
		bs.Log.Debug("Connection to Terraformer")

		opts := bs.Session.Terraformer

		tfKite, err := terraformer.Connect(opts.Endpoint, opts.SecretKey, opts.Kite)
		if err != nil {
			return err
		}
		defer tfKite.Close()

		tfReq := &terraformer.TerraformRequest{
			ContentID: req.GroupName + "-" + req.StackID,
			TraceID:   bs.TraceID,
		}

		bs.Log.Debug("Calling terraform.destroy method with context: %+v", tfReq)

		_, err = tfKite.Destroy(tfReq)
		if err != nil {
			return err
		}
	}

	return bs.Builder.Database.Destroy()
}

func (bs *BaseStack) applyAsync(ctx context.Context, req *stack.ApplyRequest) error {
	if rt, ok := stack.RequestTraceFromContext(ctx); ok {
		defer rt.Send()
	}

	bs.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Building,
	})

	if err := bs.Builder.BuildMachines(ctx); err != nil {
		return err
	}

	bs.Eventer.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	credIDs := FlattenValues(bs.Builder.Stack.Credentials)

	bs.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), bs.Req.Username)

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, req.GroupName, credIDs); err != nil {
		return err
	}

	cred, err := bs.Builder.CredentialByProvider(bs.Provider.Name)
	if err != nil {
		return err
	}

	bs.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", bs.Builder.Koding, bs.Builder.Template)

	opts := bs.Session.Terraformer

	tfKite, err := terraformer.Connect(opts.Endpoint, opts.SecretKey, opts.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	defaultContentID := req.GroupName + "-" + req.StackID
	bs.Log.Debug("Building template: %s", defaultContentID)

	if err := bs.Builder.BuildTemplate(bs.Builder.Stack.Template, defaultContentID); err != nil {
		return err
	}

	if len(req.Variables) != 0 {
		if err := bs.Builder.Template.InjectVariables("", req.Variables); err != nil {
			return err
		}
	}

	bs.Log.Debug("Stack template before injecting Koding data: %s", bs.Builder.Template)

	t, err := bs.stack.ApplyTemplate(cred)
	if err != nil {
		return err
	}

	if t.Key == "" {
		t.Key = defaultContentID
	}

	bs.Log.Debug("Stack template after injecting Koding data: %s", t)

	bs.Builder.Stack.Template = t.Content

	done := make(chan struct{})

	// because apply can last long, we are going to increment the eventer's
	// percentage as long as we build automatically.
	go func() {
		start := 45
		ticker := time.NewTicker(time.Second * 5)
		defer ticker.Stop()

		for {
			select {
			case <-done:
				return
			case <-ticker.C:
				if start < 70 {
					start += 5
				}

				bs.Eventer.Push(&eventer.Event{
					Message:    "Building stack resources",
					Percentage: start,
					Status:     machinestate.Building,
				})
			}
		}
	}()

	tfReq := &terraformer.TerraformRequest{
		Content:   bs.Builder.Stack.Template,
		ContentID: t.Key,
		TraceID:   bs.TraceID,
	}

	bs.Log.Debug("Final stack template. Calling terraform.apply method:")
	bs.Log.Debug("%+v", tfReq)

	state, err := tfKite.Apply(tfReq)

	close(done)

	if err != nil {
		return err
	}

	bs.Eventer.Push(&eventer.Event{
		Message:    "Checking VM connections",
		Percentage: 70,
		Status:     machinestate.Building,
	})

	if bs.Klients, err = bs.Planner.DialKlients(ctx, bs.KlientIDs); err != nil {
		return err
	}

	bs.Eventer.Push(&eventer.Event{
		Message:    "Updating machine settings",
		Percentage: 90,
		Status:     machinestate.Building,
	})

	err = bs.UpdateResources(state)

	if e := bs.Builder.UpdateStack(); e != nil && err == nil {
		err = e
	}

	return err
}

func (bs *BaseStack) UpdateResources(state *terraform.State) error {
	machines, err := bs.state(state)
	if err != nil {
		return err
	}

	now := time.Now().UTC()

	for label, m := range bs.Builder.Machines {
		machine, ok := machines[label]
		if !ok {
			err = multierror.Append(err, fmt.Errorf("machine %q does not exist in terraform state file", label))
			continue
		}

		if machine.Provider != bs.Planner.Provider {
			continue
		}

		if cred, e := bs.Builder.CredentialByProvider(machine.Provider); e == nil {
			machine.Credential = cred
		} else {
			err = multierror.Append(err, fmt.Errorf("machine %q: no credential found for %q provider: %s", label, machine.Provider, e))
			machine.Credential = &stack.Credential{}
		}

		state, ok := bs.Klients[label]
		if !ok {
			err = multierror.Append(err, fmt.Errorf("machine %q does not exist in dial state", label))
			continue
		}

		e := modelhelper.UpdateMachine(m.ObjectId, bson.M{"$set": bs.buildUpdateObj(machine, state, now)})
		if e != nil {
			err = multierror.Append(err, fmt.Errorf("machine %q failed to update: %s", label, e))
			continue
		}
	}

	return err
}

func (bs *BaseStack) buildUpdateObj(m *stack.Machine, s *DialState, now time.Time) bson.M {
	obj := object.MetaBuilder.Build(bs.Provider.newMetadata(m))

	obj["credential"] = m.Credential.Identifier
	obj["provider"] = bs.Provider.Name
	obj["queryString"] = m.QueryString
	obj["status.modifiedAt"] = now
	obj["status.state"] = m.State.String()
	obj["status.reason"] = m.StateReason

	for k, v := range object.MetaBuilder.Build(m.Meta) {
		obj[k] = v
	}

	if s.KiteURL != "" {
		obj["registerUrl"] = s.KiteURL

		if u, err := url.Parse(s.KiteURL); err == nil && u.Host != "" {
			if host, _, err := net.SplitHostPort(u.Host); err == nil {
				u.Host = host
			}

			obj["ipAddress"] = u.Host
		}
	}

	bs.Log.Debug("update object for %q: %+v (%# v)", m.Label, obj, s)

	return bson.M(obj)
}

func (bs *BaseStack) BuildKiteKey(label, username string) (string, error) {
	kiteID := uuid.NewV4().String()

	kiteKey, err := bs.Session.Userdata.Keycreator.Create(username, kiteID)
	if err != nil {
		return "", err
	}

	bs.KlientIDs[label] = kiteID

	return kiteKey, nil
}
