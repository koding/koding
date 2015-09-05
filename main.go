package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/koding/fuseklient/auth"
	"github.com/koding/fuseklient/transport"
	"github.com/koding/fuseklient/unmount"
	"github.com/koding/fuseklient/vmfs"
	"github.com/koding/multiconfig"
)

func main() {
	conf := new(FuseConfig)
	multiconfig.New().MustLoad(conf)

	// TODO: Remove when bundling fuseklient with klient.
	if err := auth.SaveKiteKey(conf.SshUser, conf.IP); err != nil {
		log.Fatal(err)
	}

	t, err := transport.NewKlientTransport(conf.IP)
	if err != nil {
		log.Fatal(err)
	}

	f := &vmfs.FileSystem{
		Transport:  t,
		RemotePath: conf.RemotePath,
		LocalPath:  conf.LocalPath,
		MountName:  conf.MountName,
	}

	// create mount point if it doesn't exist
	// TODO: don't allow ~ in conf.LocalPath since Go doesn't expand it
	if err := os.MkdirAll(conf.LocalPath, 0755); err != nil {
		log.Fatal(err)
	}

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL)
		<-signals

		unmount.Unmount(conf.LocalPath)
	}()

	// blocking
	if err := f.Mount(); err != nil {
		log.Fatal(err)
	}
}
