package container

import (
	"os"
	"testing"
)

const (
	ContainerName = "testContainer"
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
