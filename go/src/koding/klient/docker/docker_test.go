package docker

import (
	"errors"
	"flag"
	"log"
	"os"
	"strings"
	"testing"

	"koding/klient/testutil"

	dockerclient "github.com/fsouza/go-dockerclient"
	"github.com/koding/kite"
)

var (
	d                 *kite.Kite
	remote            *kite.Client
	TestContainerName = "dockertestnew"
	ErrNotFound       = errors.New("not found")
)

func TestMain(m *testing.M) {
	flag.Parse()

	kiteURL := testutil.GenKiteURL()

	d = kite.New("docker", "0.0.1")
	d.Config.DisableAuthentication = true
	d.Config.Port = kiteURL.Port()
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

	client, _ := dockerclient.NewVersionnedTLSClient(dockerHost, certFile, keyFile, caFile, "1.16")
	dock := &Docker{
		client: client,
		log:    d.Log,
	}

	d.HandleFunc("create", dock.Create)
	d.HandleFunc("start", dock.Start)
	d.HandleFunc("connect", dock.Connect) // TODO: doesn't work inside our tests, look at it
	d.HandleFunc("stop", dock.Stop)
	d.HandleFunc("list", dock.List)
	d.HandleFunc("remove", dock.RemoveContainer)

	go d.Run()
	<-d.ServerReadyNotify()
	defer d.Close()

	remote = d.NewClient(kiteURL.String())
	err := remote.Dial()
	if err != nil {
		log.Fatalf("err")
	}
	defer remote.Close()

	os.Exit(m.Run())
}

func TestDockerCreate(t *testing.T) {
	resp, err := remote.Tell("create", struct {
		Name  string
		Image string
	}{
		Name: TestContainerName,
		// we choose redis because it's a long living, blocking container. It
		// uses a "entrypoint.sh" script as entrypoint so it doesn't exit once
		// we start it
		Image: "redis",
	})
	if err != nil {
		t.Fatal(err)
	}

	if TestContainerName != resp.MustString() {
		t.Errorf("container name is wrong, have '%s', want '%s'",
			resp.MustString(), TestContainerName)
	}
}

func TestDockerStart(t *testing.T) {
	container, err := getContainer(TestContainerName)
	if err != nil {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}

	_, err = remote.Tell("start", struct {
		ID string
	}{
		ID: container.ID,
	})
	if err != nil {
		t.Fatal(err)
	}

	container, err = getContainer(TestContainerName)
	if err != nil {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}

	if container.Status == "" {
		t.Fatal("container should be running, but we have nothing")
	}

	if strings.Contains(container.Status, "Exit") {
		t.Fatalf("container is not running: %s", container.Status)
	}
}

func TestDockerConnect(t *testing.T) {
	container, err := getContainer(TestContainerName)
	if err != nil {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}

	_, err = remote.Tell("connect", struct {
		ID string
	}{
		ID: container.ID,
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestDockerStop(t *testing.T) {
	container, err := getContainer(TestContainerName)
	if err != nil {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}

	_, err = remote.Tell("stop", struct {
		ID string
	}{
		ID: container.ID,
	})
	if err != nil {
		t.Fatal(err)
	}

	container, err = getContainer(TestContainerName)
	if err != nil {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}

	if !strings.Contains(container.Status, "Exit") {
		t.Fatalf("container is not stopped: %s", container.Status)
	}
}

func TestDockerList(t *testing.T) {
	container, err := getContainer(TestContainerName)
	if err != nil {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}

	if container.Names[0] != "/"+TestContainerName {
		t.Errorf("container name is wrong, have '%s', want '%s'", container.Names[0], TestContainerName)
	}
}

func TestDockerRemoveContainer(t *testing.T) {
	container, err := getContainer(TestContainerName)
	if err != nil {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}

	if container.ID == "" {
		t.Error("container Id is empty, can't remove anything")
		return
	}

	_, err = remote.Tell("remove", struct {
		ID string
	}{
		ID: container.ID,
	})
	if err != nil {
		t.Fatal(err)
	}

	_, err = getContainer(TestContainerName)
	if err != nil && err != ErrNotFound {
		t.Errorf("No image found with name '%s': %s\n", TestContainerName, err)
	}
}

func getContainer(containerName string) (*dockerclient.APIContainers, error) {
	resp, err := remote.Tell("list")
	if err != nil {
		return nil, err
	}

	var containers []dockerclient.APIContainers

	err = resp.Unmarshal(&containers)
	if err != nil {
		return nil, err
	}

	for _, container := range containers {
		name := container.Names[0]
		// there is a slash in front of the names, so include it
		if name == "/"+containerName {
			return &container, nil
		}
	}

	return nil, ErrNotFound
}
