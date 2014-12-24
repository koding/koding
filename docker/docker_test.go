package docker

import (
	"fmt"
	"log"
	"os"
	"testing"

	dockerclient "github.com/koding/klient/Godeps/_workspace/src/github.com/fsouza/go-dockerclient"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

var (
	d                 *kite.Kite
	remote            *kite.Client
	TestContainerName = "dockertest"
)

func init() {
	d = kite.New("docker", "0.0.1")
	d.Config.DisableAuthentication = true
	d.Config.Port = 3636
	d.Config.Username = "dockertest"

	dockerHost := os.Getenv("DOCKER_HOST")
	if dockerHost == "" {
		dockerHost = "tcp://192.168.59.103:2376" // darwin, boot2docker
	}

	dockerCertPath := os.Getenv("DOCKER_CERT_PATH")
	if dockerCertPath == "" {
		panic("please set DOCKER_CERT_PATH")
	}

	certFile := dockerCertPath + "/cert.pem"
	keyFile := dockerCertPath + "/key.pem"
	caFile := dockerCertPath + "/ca.pem"

	client, _ := dockerclient.NewTLSClient(dockerHost, certFile, keyFile, caFile)
	dock := &Docker{
		client: client,
	}

	d.HandleFunc("list", dock.List)
	d.HandleFunc("create", dock.Create)

	go d.Run()
	<-d.ServerReadyNotify()

	remote = d.NewClient("http://127.0.0.1:3636/kite")
	err := remote.Dial()
	if err != nil {
		log.Fatal("err")
	}
}

func TestCreate(t *testing.T) {
	resp, err := remote.Tell("create", struct {
		Name  string
		Image string
	}{
		Name:  TestContainerName,
		Image: "ubuntu",
	})
	if err != nil {
		t.Fatal(err)
	}

	if containerName != resp.MustString() {
		t.Errorf("container name is wrong, have '%s', want '%s'",
			resp.MustString(), containerName)
	}

	containerName := resp.MustString()
	fmt.Printf("containerName %+v\n", containerName)
}

func TestList(t *testing.T) {
	resp, err := remote.Tell("list")
	if err != nil {
		t.Fatal(err)
	}

	var containers []dockerclient.APIContainers

	err = resp.Unmarshal(&containers)
	if err != nil {
		t.Error(err)
	}

	for _, container := range containers {
		image := container.Image
		name := container.Names[0]
		t.Logf("image, name: %s, %s\n", image, name)
		// there is a slash in front of the names, so include it
		if name == "/"+TestContainerName {
			return // successfull
		}
	}

	t.Errorf("No image found with name '%s'\n", TestContainerName)
}
