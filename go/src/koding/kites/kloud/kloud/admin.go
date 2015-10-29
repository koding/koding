package kloud

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	"time"

	"golang.org/x/net/context"

	"github.com/koding/kite"
)

type AdminRequest struct {
	MachineId string `json:"machineId"`
	GroupName string `json:"groupName"`
}

func (k *Kloud) AdminAdd(r *kite.Request) (interface{}, error) {
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
		return nil, errors.New("group name is not passed")
	}

	admins, err := modelhelper.FetchAdminAccounts(args.GroupName)
	if err != nil {
		return nil, err
	}

	isAdmin := false
	for _, admin := range admins {
		if admin.Profile.Nickname == r.Username {
			isAdmin = true
		}
	}
	if !isAdmin {
		return nil, fmt.Errorf("User '%s' is not an admin of group '%s'", r.Username, args.GroupName)
	}

	machine, err := modelhelper.GetMachine(args.MachineId)
	if err != nil {
		return nil, err
	}

	// fetch jGroup from group slug name
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
		return nil, fmt.Errorf("Group '%s' is not a member of machine '%s'", args.GroupName, args.MachineId)
	}
	// Now we are ready to go

	ctx := request.NewContext(context.Background(), r)
	ctx = k.ContextCreator(ctx)
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	kl, err := klient.NewWithTimeout(sess.Kite, machine.QueryString, time.Second*10)
	if err != nil {
		return nil, err
	}

	if err := kl.AddUser(r.Username); err != nil {
		return nil, err
	}

	return true, nil
}

// func (k *Kloud) AdminRemove(r *kite.Request) (interface{}, error) {
// 	if r.Args == nil {
// 		return nil, NewError(ErrNoArguments)
// 	}
//
// 	var args *AdminRequest
// 	if err := r.Args.One().Unmarshal(&args); err != nil {
// 		return nil, err
// 	}
//
// 	if args.MachineId == "" {
// 		return nil, errors.New("machineId is not passed")
// 	}
//
// 	if args.GroupName == "" {
// 		return nil, errors.New("group name is not passed")
// 	}
// }
