// +build darwin,linux
package app

import (
	"koding/kites/metrics"

	"github.com/koding/kite"
)

func (k *Klient) addRemoteHandlers() {
	// Remote handles interaction specific to remote Klient machines.
	k.handleRemoteFunc("remote.cacheFolder", k.remote.CacheFolderHandler)
	k.handleRemoteFunc("remote.list", k.remote.ListHandler)
	k.handleRemoteFunc("remote.mounts", k.remote.MountsHandler)
	k.handleRemoteFunc("remote.mountFolder", k.remote.MountFolderHandler)
	k.handleRemoteFunc("remote.unmountFolder", k.remote.UnmountFolderHandler)
	k.handleRemoteFunc("remote.sshKeysAdd", k.remote.SSHKeyAddHandler)
	k.handleRemoteFunc("remote.exec", k.remote.ExecHandler)
	k.handleRemoteFunc("remote.status", k.remote.StatusHandler)
	k.handleRemoteFunc("remote.remount", k.remote.RemountHandler)
	k.handleRemoteFunc("remote.mountInfo", k.remote.MountInfoHandler)
	k.handleRemoteFunc("remote.readDirectory", k.remote.ReadDirectoryHandler)
	k.handleRemoteFunc("remote.currentUsername", k.remote.CurrentUsername)
	k.handleRemoteFunc("remote.getPathSize", k.remote.GetPathSize)
}

func (k *Klient) handleRemoteFunc(method string, fn kite.HandlerFunc) {
	fn = metrics.WrapKiteHandler(k.metrics.Datadog, method, fn)
	k.kite.HandleFunc(method, func(r *kite.Request) (interface{}, error) {
		resp, err := fn(r)
		if err != nil {
			return nil, err
		}

		k.presenceEvery.Do(func() {
			if err := k.ping(); err != nil {
				k.log.Error("Failed to ping: %s", err)
			}
		})

		return resp, nil
	})
}
