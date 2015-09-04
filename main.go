package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/koding/multiconfig"
)

func main() {
	conf := new(FuseConfig)
	multiconfig.New().MustLoad(conf)

	if conf.Debug {
		shouldDebug = true
	}

	// TODO: Remove when bundling fuseklient with klient
	if err := runInstallAlpha(conf.SshUser, conf.KlientIP); err != nil {
		log.Fatal(err)
	}

	t, err := NewKlientTransport(conf.KlientIP)
	if err != nil {
		log.Fatal(err)
	}

	f := &FileSystem{
		Transport:         t,
		ExternalMountPath: conf.ExternalPath,
		InternalMountPath: conf.InternalPath,
		MountName:         conf.MountName,
	}

	// create mount point if it doesn't exist
	// TODO: don't allow ~ in conf.InternalPath since Go doesn't expand it
	if err := os.MkdirAll(conf.InternalPath, 0755); err != nil {
		log.Fatal(err)
	}

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL)
		<-signals

		unmount(conf.InternalPath)
	}()

	// blocking
	if err := f.Mount(); err != nil {
		log.Fatal(err)
	}
}
