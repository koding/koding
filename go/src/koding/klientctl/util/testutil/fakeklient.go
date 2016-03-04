package testutil

import (
	"koding/klient/remote/req"
	"koding/klientctl/list"
)

type FakeKlient struct {
	ReturnInfos list.KiteInfos

	ReturnMountInfo    req.MountInfoResponse
	ReturnMountInfoErr error
}

func (k *FakeKlient) RemoteStatus(req.Status) error {
	return nil
}

func (k *FakeKlient) RemoteList() (list.KiteInfos, error) {
	return k.ReturnInfos, nil
}

func (k *FakeKlient) RemoteMountInfo(string) (req.MountInfoResponse, error) {
	return k.ReturnMountInfo, k.ReturnMountInfoErr
}
