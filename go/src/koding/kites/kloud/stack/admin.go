package stack

import (
	"errors"
	"fmt"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type AdminRequest struct {
	MachineId string `json:"machineId"`
	GroupName string `json:"groupName"`
}

func (k *Kloud) AdminAdd(r *kite.Request) (interface{}, error) {
	kl, err := k.authorizedKlient(r)
	if err != nil {
		return nil, err
	}

	if err := kl.AddUser(r.Username); err != nil {
		return nil, err
	}

	return true, nil
}

func (k *Kloud) AdminRemove(r *kite.Request) (interface{}, error) {
	kl, err := k.authorizedKlient(r)
	if err != nil {
		return nil, err
	}

	if err := kl.RemoveUser(r.Username); err != nil {
		return nil, err
	}

	return true, nil
}

func (k *Kloud) authorizedKlient(r *kite.Request) (*klient.Klient, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *AdminRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is not passed")
	}

	if args.GroupName == "" {
		return nil, errors.New("groupName is not passed")
	}

	k.Log.Debug("Got arguments %+v for method: %s", args, r.Method)

	isAdmin, err := modelhelper.IsAdmin(r.Username, args.GroupName)
	if err != nil {
		return nil, err
	}

	if !isAdmin {
		return nil, fmt.Errorf("User '%s' is not an admin of group '%s'", r.Username, args.GroupName)
	}

	k.Log.Debug("User '%s' is an admin. Checking for machine permission", r.Username)

	machine, err := modelhelper.GetMachine(args.MachineId)
	if err != nil {
		return nil, fmt.Errorf("getMachine(%s) err: %s", args.MachineId, err)
	}

	g, err := modelhelper.GetGroup(args.GroupName)
	if err != nil {
		return nil, err
	}

	isGroupMember := false
	for _, group := range machine.Groups {
		if group.Id.Hex() == g.Id.Hex() {
			isGroupMember = true
		}
	}
	if !isGroupMember {
		return nil, fmt.Errorf("'%s' machine does not belong to '%s' group",
			args.MachineId, args.GroupName)
	}

	k.Log.Debug("Incoming user is authorized, setting up DB and Klient connection")

	// Now we are ready to go.
	ctx := request.NewContext(context.Background(), r)
	ctx = k.ContextCreator(ctx)
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("internal server error (err: session context is not available)")
	}

	k.Log.Debug("Calling Klient method: %s", r.Method)
	return klient.NewWithTimeout(sess.Kite, machine.QueryString, time.Second*10)
}
