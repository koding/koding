// +build darwin,linux
package app

func (k *Klient) addRemoteHandlers() {
	// Remote handles interaction specific to remote Klient machines.
	k.kite.HandleFunc("remote.cacheFolder", k.remote.CacheFolderHandler)
	k.kite.HandleFunc("remote.list", k.remote.ListHandler)
	k.kite.HandleFunc("remote.mounts", k.remote.MountsHandler)
	k.kite.HandleFunc("remote.mountFolder", k.remote.MountFolderHandler)
	k.kite.HandleFunc("remote.unmountFolder", k.remote.UnmountFolderHandler)
	k.kite.HandleFunc("remote.sshKeysAdd", k.remote.SSHKeyAddHandler)
	k.kite.HandleFunc("remote.exec", k.remote.ExecHandler)
	k.kite.HandleFunc("remote.status", k.remote.StatusHandler)
	k.kite.HandleFunc("remote.remount", k.remote.RemountHandler)
	k.kite.HandleFunc("remote.mountInfo", k.remote.MountInfoHandler)
	k.kite.HandleFunc("remote.readDirectory", k.remote.ReadDirectoryHandler)
	k.kite.HandleFunc("remote.currentUsername", k.remote.CurrentUsername)
	k.kite.HandleFunc("remote.getPathSize", k.remote.GetPathSize)
}

// Initializing the remote re-establishes any previously-running remote
// connections, such as mounted folders. This needs to be run *after*
// Klient is setup and running, to get a valid connection to Kontrol.
func (k *Klient) initRemote() {
	if err := k.remote.Initialize(); err != nil {
		k.log.Error("Failed to initialize Remote. Error: %s", err.Error())
	}
}
