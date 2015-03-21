package koding

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"

	"golang.org/x/net/context"
)

func (m *Machine) Build(ctx context.Context) error {
	_, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not available")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("req context is not available")
	}

	// the usre might send us a snapshot id
	var args struct {
		SnapshotId string
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

	fmt.Println("hurraaa!")

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

// func (m *Machine) UpdateState(reason string, state machinestate.State) error {
// 	m.Log.Debug("[%s] Updating state to '%v'", id, state)
// 	err := p.Session.Run("jMachines", func(c *mgo.Collection) error {
// 		return c.Update(
// 			bson.M{
// 				"_id": bson.ObjectIdHex(id),
// 			},
// 			bson.M{
// 				"$set": bson.M{
// 					"status.state":      state.String(),
// 					"status.modifiedAt": time.Now().UTC(),
// 					"status.reason":     reason,
// 				},
// 			},
// 		)
// 	})
//
// 	if err != nil {
// 		return fmt.Errorf("Couldn't update state to '%s' for document: '%s' err: %s",
// 			state, id, err)
// 	}
//
// 	return nil
// }
