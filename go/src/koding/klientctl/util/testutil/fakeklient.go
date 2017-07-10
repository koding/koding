package testutil

import (
	"koding/klient/command"
	"koding/klient/fs"
	"koding/klient/remote/req"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

type FakeKlient struct {
	callCounts map[string]int

	ReturnClient *kite.Client

	ReturnMountInfo    req.MountInfoResponse
	ReturnMountInfoErr error

	ReturnRemountErr error

	ReturnRemoteExec    command.Output
	ReturnRemoteExecErr error

	ReturnRemoteCacheErr error

	ReturnRemoteMountFolderWarning string
	ReturnRemoteMountFolderErr     error

	ReturnTellPartial *dnode.Partial
	ReturnTellErr     error
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

func (k *FakeKlient) GetClient() *kite.Client {
	return k.ReturnClient
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

func (k *FakeKlient) RemoteCache(req.Cache, func(par *dnode.Partial)) error {
	return k.ReturnRemoteCacheErr
}

func (k *FakeKlient) RemoteMountFolder(req.MountFolder) (string, error) {
	return k.ReturnRemoteMountFolderWarning, k.ReturnRemoteMountFolderErr
}

func (k *FakeKlient) Tell(string, ...interface{}) (*dnode.Partial, error) {
	return k.ReturnTellPartial, k.ReturnTellErr
}

func (k *FakeKlient) RemoteReadDirectory(string, string) ([]fs.FileEntry, error) {
	return nil, nil
}

func (k *FakeKlient) RemoteCurrentUsername(req.CurrentUsernameOptions) (string, error) {
	return "", nil
}

func (k *FakeKlient) RemoteGetPathSize(opts req.GetPathSizeOptions) (uint64, error) {
	return 0, nil
}
