package container

import (
	"net"
	"os"
	"testing"
)

const (
	ContainerName = "testContainer"
	ContainerType = "busybox"
	PrepareHost   = "vagrant"
	PrepareName   = "vm-test"
)

func TestNewContainer(t *testing.T) {
	c := NewContainer(ContainerName)

	if c.Name != ContainerName {
		t.Errorf("NewContainer: exptecting: %s got: %s", ContainerName, c.Name)
	}

	containerDir := lxcDir + ContainerName + "/"

	if c.Dir != containerDir {
		t.Errorf("NewContainer: exptecting: %s got: %s", containerDir, c.Dir)
	}

}

func TestContainer_Mkdir(t *testing.T) {
	c := NewContainer(ContainerName)
	c.Mkdir("/")

	if _, err := os.Stat(c.Dir); os.IsNotExist(err) {
		t.Errorf("Mkdir: %s does not exist", c.Dir)
	}
}

func TestContainer_GenerateFiles(t *testing.T) {
	c := NewContainer(ContainerName)
	c.IP = net.ParseIP("127.0.0.1")
	c.HostnameAlias = "vagrant"

	var files = []struct {
		fileName string
		template string
	}{
		{"config", "config"},
		{"fstab", "fstab"},
		{"ip-address", "ip-address"},
	}

	for _, file := range files {
		err := c.GenerateFile(file.fileName, file.template)
		if err != nil {
			t.Errorf("Generatefile: %s ", err)
		}

		if _, err := os.Stat(c.Dir + file.fileName); os.IsNotExist(err) {
			t.Errorf("Generatefile: %s does not exist", c.Dir+file.fileName)
		}
	}

}

// func TestContainer_Create(t *testing.T) {
// 	c := NewContainer(ContainerName)

// 	if err := c.Create(ContainerType); err != nil {
// 		t.Error(err)
// 	}

// 	if _, err := os.Stat(c.Dir); os.IsNotExist(err) {
// 		t.Errorf("Create: %s does not exist", c.Dir)
// 	}

// }

// func TestContainer_Start(t *testing.T) {
// 	c := NewContainer(ContainerName)

// 	if err := c.Start(); err != nil {
// 		t.Error(err)
// 	}

// 	if !c.IsRunning() {
// 		t.Errorf("Starting the container failed...")
// 	}
// }

// func TestShutdown(t *testing.T) {
// 	c := NewContainer(ContainerName)

// 	if err := c.Shutdown(3); err != nil {
// 		t.Errorf(err.Error())
// 	}

// 	if c.IsRunning() {
// 		t.Errorf("Shutting down the container failed...")
// 	}
// }

// func TestStop(t *testing.T) {
// 	c := NewContainer(ContainerName)

// 	if err := c.Start(); err != nil {
// 		t.Error(err)
// 	}

// 	if err := c.Stop(); err != nil {
// 		t.Errorf(err.Error())
// 	}

// 	if c.IsRunning() {
// 		t.Errorf("Stopping the container failed...")
// 	}
// }

// func TestDestroy(t *testing.T) {
// 	c := NewContainer(ContainerName)

// 	if err := c.Destroy(); err != nil {
// 		t.Error(err)
// 	}
// }
