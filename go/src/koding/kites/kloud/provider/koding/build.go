package koding

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

func (m *Machine) Build(ctx context.Context) error {
	m.Log.Info("========== BUILD started (user: %s) ==========", m.Username)

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return errors.New("session context is not available")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("req context is not available")
	}

	// the usre might send us a snapshot id or reason
	var args struct {
		SnapshotId string
		Reason     string
	}

	if err := req.Args.One().Unmarshal(&args); err != nil {
		return err
	}

	// Check if the given method is in valid methods of that current state. For
	// example if the method is "build", and the state is "stopped" than this
	// will return an error.
	if !methodIn(req.Method, m.State().ValidMethods()...) {
		return fmt.Errorf("method '%s' not allowed for current state '%s'. Allowed methods are: %v",
			req.Method, strings.ToLower(m.Status.State), m.State().ValidMethods())
	}

	if m.Meta.InstanceName == "" {
		m.Meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	// get our state pair. A state pair defines the initial and final state of
	// a method.  For example, for "restart" method the initial state is
	// "rebooting" and the final "running.
	s, ok := states[req.Method]
	if !ok {
		return fmt.Errorf("no state pair available for %s", req.Method)
	}

	// check if the argument has any Reason, and add it to the existing reason.
	initialReason := fmt.Sprintf("Machine is '%s' due user command: '%s'.", s.initial, req.Method)
	if args.Reason != "" {
		initialReason += "Custom reason: " + args.Reason
	}

	m.UpdateState(initialReason, s.initial)

	// push the first event so it's filled with it, let people know that we're
	// starting.
	ev.Push(&eventer.Event{
		Message: fmt.Sprintf("Starting %s", req.Method),
		Status:  s.initial,
	})

	start := time.Now()
	currentState := m.State()
	status := s.final
	finishReason := fmt.Sprintf("Machine is '%s' due user command: '%s'", s.final, req.Method)
	msg := fmt.Sprintf("%s is finished successfully.", req.Method)
	eventErr := ""

	err := m.build()
	if err != nil {
		m.Log.Error("%s failed. State is set back to origin '%s'. err: %s",
			req.Method, currentState, err.Error())

		status = currentState

		msg = ""

		// special case `NetworkOut` error since client relies on this
		// to show a modal
		if strings.Contains(err.Error(), "NetworkOut") {
			msg = err.Error()
		}

		// special case `plan is expired` error since client relies on this
		// to show a modal
		if strings.Contains(strings.ToLower(err.Error()), "plan is expired") {
			msg = err.Error()
		}

		eventErr = fmt.Sprintf("%s failed. Please contact support.", req.Method)
		finishReason = fmt.Sprintf("User command: '%s' failed. Setting back to state: %s",
			req.Method, currentState)

		m.Log.Info("========== BUILD failed (user: %s) ==========", m.Username)
	} else {
		totalDuration := time.Since(start)
		m.Log.Info(" ========== BUILD finished with success (user: %s, duration: %s) ==========",
			m.Username, totalDuration)
	}

	// update final status in storage
	if args.Reason != "" {
		finishReason += "Custom reason: " + args.Reason
	}

	m.UpdateState(finishReason, status)

	ev.Push(&eventer.Event{
		Message:    msg,
		Status:     status,
		Percentage: 100,
		Error:      eventErr,
	})

	return nil
}

func (m *Machine) build() error {
	fmt.Println("building!")
	return nil
}

// methodIn checks if the method exist in the given methods
func methodIn(method string, methods ...string) bool {
	for _, m := range methods {
		if method == m {
			return true
		}
	}
	return false
}

func (m *Machine) UpdateState(reason string, state machinestate.State) error {
	m.Log.Debug("Updating state to '%v'", state)
	err := m.Context.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Update(
			bson.M{
				"_id": m.Id,
			},
			bson.M{
				"$set": bson.M{
					"status.state":      state.String(),
					"status.modifiedAt": time.Now().UTC(),
					"status.reason":     reason,
				},
			},
		)
	})

	if err != nil {
		return fmt.Errorf("Couldn't update state to '%s' for document: '%s' err: %s",
			state, m.Id.Hex(), err)
	}

	return nil
}
