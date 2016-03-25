package testutil

import (
	"koding/klient/command"
	"koding/klient/remote/req"
	"koding/klientctl/list"
)

type FakeKlient struct {
	callCounts map[string]int

	ReturnInfos list.KiteInfos

	ReturnMountInfo    req.MountInfoResponse
	ReturnMountInfoErr error

	ReturnRemountErr error

	ReturnRemoteExec    command.Output
	ReturnRemoteExecErr error
}

func (k *FakeKlient) incrementCallCount(method string) {
	k.SetCallCount(method, k.GetCallCount(method)+1)
}

func (k *FakeKlient) SetCallCount(method string, count int) {
	if k.callCounts == nil {
		k.callCounts = map[string]int{}
	}

	k.callCounts[method] = count
}

func (k *FakeKlient) GetCallCount(method string) int {
	if k.callCounts == nil {
		k.callCounts = map[string]int{}
	}

	c, _ := k.callCounts[method]
	return c
}

func (k *FakeKlient) RemoteStatus(req.Status) error {
	k.incrementCallCount("RemoteStatus")
	return nil
}

func (k *FakeKlient) RemoteList() (list.KiteInfos, error) {
	k.incrementCallCount("RemoteList")
	return k.ReturnInfos, nil
}

func (k *FakeKlient) RemoteMountInfo(string) (req.MountInfoResponse, error) {
	k.incrementCallCount("RemoteMountInfo")
	return k.ReturnMountInfo, k.ReturnMountInfoErr
}

func (k *FakeKlient) RemoteRemount(string) error {
	k.incrementCallCount("RemoteRemount")
	return k.ReturnRemountErr
}

func (k *FakeKlient) RemoteExec(string, string) (command.Output, error) {
	k.incrementCallCount("RemoteExec")
	return k.ReturnRemoteExec, k.ReturnRemoteExecErr
}
