package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"

	"github.com/koding/multiconfig"
)

func main() {
	conf := new(FuseConfig)
	multiconfig.New().MustLoad(conf)

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
	if err := os.MkdirAll(conf.InternalPath, 0755); err != nil {
		log.Fatal(err)
	}

	go unmountOnExit(conf.InternalPath)

	// blocking
	if err := f.Mount(); err != nil {
		log.Fatal(err)
	}
}

func unmountOnExit(folder string) {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL)

	<-signals

	_, err := exec.Command("diskutil", "unmount", "force", folder).CombinedOutput()
	if err != nil {
		fmt.Println("Unmount failed. Please do `diskutil unmount force <folder>`.")
	}

	os.Exit(0)
}
