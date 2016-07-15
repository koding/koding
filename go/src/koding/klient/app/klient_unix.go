// +build darwin,linux
package app

import (
	"koding/s3logrotate"
	"runtime"
	"time"
)

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

	go k.sendLogsOnInterval(LogLocations())
}

// sendLogsOnInterval sends klient and kd logs files to write only s3 bucket
// in an interval.
func (k *Klient) sendLogsOnInterval(logLocs []string) {
	u, err := s3logrotate.NewUploadClient(
		k.config.LogBucketRegion,
		k.config.LogBucketName,
	)
	if err != nil {
		k.log.Error("s3logrotate: Failed to initialize client. Error: %s", err)
	}

	t := time.Tick(k.config.LogUploadInterval)
	for _ = range t {
		c := s3logrotate.New(int64(k.config.LogUploadLimit), u, logLocs...)
		if err := c.ReadAndUpload(); err != nil {
			k.log.Error("s3logrotate: Failed to send logs. Error: %s", err)
		}
	}
}

func LogLocations() []string {
	if runtime.GOOS == "darwin" {
		return []string{"/Library/Logs/klient.log", "/Library/Logs/kd.log"}
	}

	if runtime.GOOS == "linux" {
		return []string{"/var/log/upstart/klient.log", "/var/log/upstart/kd.log"}
	}

	return nil
}
