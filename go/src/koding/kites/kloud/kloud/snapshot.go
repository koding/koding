package kloud

// func (k *Kloud) CreateSnapshot(r *kite.Request) (reqResp interface{}, reqErr error) {
// 	resizeFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		resp, err := p.CreateSnapshot(m)
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		// some providers might provide empty information, therefore do not
// 		// update anything for them
// 		if resp == nil {
// 			return true, nil
// 		}
//
// 		err = k.Storage.Update(m.Id, &StorageData{
// 			Type: "createSnapshot",
// 			Data: map[string]interface{}{
// 				"ipAddress": resp.IpAddress,
// 			},
// 		})
//
// 		if err != nil {
// 			k.Log.Error("[%s] updating data after createSnapshot method was not possible: %s",
// 				m.Id, err.Error())
// 			return fmt.Errorf("[%s] could not update data for snapshot. Please contact support", m.Id), nil
// 		}
//
// 		return resp, nil
// 	}
//
// 	return k.coreMethods(r, resizeFunc)
// }
//
// func (k *Kloud) DeleteSnapshot(r *kite.Request) (interface{}, error) {
// 	// don't get a beloved panic
// 	if r.Args == nil {
// 		return nil, NewError(ErrNoArguments)
// 	}
//
// 	var args struct {
// 		MachineId  string `json:"machineId"`
// 		SnapshotId string `json:"snapshotId"`
// 	}
//
// 	if err := r.Args.One().Unmarshal(&args); err != nil {
// 		return nil, err
// 	}
//
// 	if args.SnapshotId == "" {
// 		return nil, NewError(ErrSnapshotIdMissing)
// 	}
//
// 	m, err := k.PrepareMachine(r)
// 	if err != nil {
// 		return nil, err
// 	}
// 	defer k.Locker.Unlock(m.Id)
//
// 	// fake eventer to avoid panics if someone tries to use the eventer
// 	m.Eventer = &eventer.Events{}
//
// 	provider, ok := k.providers[m.Provider]
// 	if !ok {
// 		return nil, NewError(ErrProviderAvailable)
// 	}
//
// 	controller, ok := provider.(protocol.Provider)
// 	if !ok {
// 		return nil, NewError(ErrProviderNotImplemented)
// 	}
//
// 	if err := controller.DeleteSnapshot(args.SnapshotId, m); err != nil {
// 		return nil, err
// 	}
//
// 	return true, nil
// }
