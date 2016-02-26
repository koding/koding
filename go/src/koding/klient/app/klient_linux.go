package app

// Remote handlers are disabled for linux, currently.
func (k *Klient) addRemoteHandlers() {}

// Remote is disabled for linux, currently.
func (k *Klient) initRemote() {
	k.log.Warning("Disabling Remote Initialization. Klientctl should not use this binary.")
}
