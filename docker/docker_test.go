package docker

import (
	"fmt"
	"log"
	"os"
	"testing"

	dockerclient "github.com/fsouza/go-dockerclient"
	"github.com/koding/kite"
)

var (
	d      *kite.Kite
	remote *kite.Client
)

func init() {
	d = kite.New("docker", "0.0.1")
	d.Config.DisableAuthentication = true
	d.Config.Port = 3636

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

	go d.Run()
	<-d.ServerReadyNotify()

	remote = d.NewClient("http://127.0.0.1:3636/kite")
	err := remote.Dial()
	if err != nil {
		log.Fatal("err")
	}
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

	fmt.Printf("len(containers) %+v\n", len(containers))
	for _, container := range containers {
		image := container.Image
		fmt.Printf("image %+v\n", image)
	}
}
