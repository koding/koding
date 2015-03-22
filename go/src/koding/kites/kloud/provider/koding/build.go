package koding

import (
	"errors"
	"fmt"
	"strconv"
	"time"

	"koding/kites/kloud/contexthelper/request"

	"golang.org/x/net/context"
)

func (m *Machine) Build(ctx context.Context) (err error) {
	return m.runMethod(ctx, m.build)
}

func (m *Machine) build(ctx context.Context) error {
	m.Log.Info("========== BUILD started (user: %s) ==========", m.Username)

	// ev, ok := eventer.FromContext(ctx)
	// if !ok {
	// 	return errors.New("session context is not available")
	// }

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("req context is not available")
	}

	// the user might send us a snapshot id
	var args struct {
		SnapshotId string
	}

	if err := req.Args.One().Unmarshal(&args); err != nil {
		return err
	}

	if m.Meta.InstanceName == "" {
		m.Meta.InstanceName = "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	fmt.Println("building!")
	return nil
}
