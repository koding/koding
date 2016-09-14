package provider

import (
	"fmt"
	"strings"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/stackstate"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
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
func (bs *BaseStack) Apply(ctx context.Context) (interface{}, error) {
	var arg stack.ApplyRequest
	if err := bs.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	err := bs.Builder.BuildStack(arg.StackID, arg.Credentials)

	if err != nil && !(arg.Destroy && stackplan.IsNotFound(err, "jStackTemplate")) {
		return nil, err
	}

	if state := bs.Builder.Stack.Stack.State(); state.InProgress() {
		return nil, fmt.Errorf("State is currently %s. Please try again later", state)
	}

	if rt, ok := stack.RequestTraceFromContext(ctx); ok {
		rt.Hijack()
	}

	if arg.Destroy {
		err = bs.destroy(ctx, &arg)
	} else {
		err = bs.apply(ctx, &arg)
	}

	if err != nil {
		return nil, err
	}

	return stack.ControlResult{
		EventId: bs.Eventer.ID(),
	}, nil
}

func (bs *BaseStack) apply(ctx context.Context, req *stack.ApplyRequest) error {
	log := bs.Log.New(req.StackID)

	bs.Eventer.Push(&eventer.Event{
		Message: bs.Req.Method + " started",
		Status:  machinestate.Building,
	})

	go func() {
		finalEvent := &eventer.Event{
			Message:    bs.Req.Method + " finished",
			Status:     machinestate.Running,
			Percentage: 100,
		}

		start := time.Now()

		modelhelper.SetStackState(req.StackID, "Stack building started", stackstate.Building)
		log.Info("======> %s started <======", strings.ToUpper(bs.Req.Method))

		if err := bs.applyAsync(ctx, req); err != nil {
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

	return nil
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

	credIDs := stackplan.FlattenValues(bs.Builder.Stack.Credentials)

	bs.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), bs.Req.Username)

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, req.GroupName, credIDs); err != nil {
		return err
	}

	bs.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", bs.Builder.Koding, bs.Builder.Template)

	if bs.Builder.Stack.Stack.State() != stackstate.NotInitialized {
		bs.Log.Debug("Connection to Terraformer")

		tfKite, err := terraformer.Connect(bs.Session.Terraformer)
		if err != nil {
			return err
		}
		defer tfKite.Close()

		tfReq := &tf.TerraformRequest{
			ContentID: req.GroupName + "-" + req.StackID,
			TraceID:   bs.TraceID,
		}

		bs.Log.Debug("Calling terraform.destroy method with context:")
		bs.Log.Debug("%+v", tfReq)

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

	credIDs := stackplan.FlattenValues(bs.Builder.Stack.Credentials)

	bs.Log.Debug("Fetching '%d' credentials from user '%s'", len(credIDs), bs.Req.Username)

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, req.GroupName, credIDs); err != nil {
		return err
	}

	bs.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", bs.Builder.Koding, bs.Builder.Template)
	bs.Log.Debug("Connection to Terraformer")

	tfKite, err := terraformer.Connect(bs.Session.Terraformer)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	contentID := req.GroupName + "-" + req.StackID
	bs.Log.Debug("Building template: %s", contentID)

	if err := bs.Builder.BuildTemplate(bs.Builder.Stack.Template, contentID); err != nil {
		return err
	}

	bs.Log.Debug("Stack template before injecting Koding data:")
	bs.Log.Debug("%s", bs.Builder.Template)

	bs.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")

	if err := bs.BuildResources(); err != nil {
		return err
	}

	out, err := bs.Builder.Template.JsonOutput()
	if err != nil {
		return err
	}

	bs.Builder.Stack.Template = out

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

	tfReq := &tf.TerraformRequest{
		Content:   bs.Builder.Stack.Template,
		ContentID: contentID,
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

	if err := bs.WaitResources(ctx); err != nil {
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
