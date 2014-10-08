package main

import (
	"fmt"
	"log"
	"net/url"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/testkeys"
	"github.com/koding/kite/testutil"

	"koding/kites/kloud/idlock"
	"koding/kites/kloud/keys"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/koding"
	"koding/kites/kloud/machinestate"
	kloudprotocol "koding/kites/kloud/protocol"
	"koding/kites/kloud/sshutil"

	"github.com/mitchellh/goamz/ec2"
)

var (
	kloudKite *kite.Kite
	kld       *kloud.Kloud
	remote    *kite.Client
	conf      *config.Config
	provider  *koding.Provider
)

const (
	machineId0 = "koding_id0"
	etcdIp     = "192.168.59.103:4001"
)

type args struct {
	MachineId string
}

func init() {
	conf = config.New()
	conf.Username = "testuser"
	conf.KontrolURL = "http://localhost:4099/kite"
	conf.KontrolKey = testkeys.Public
	conf.KontrolUser = "testuser"
	conf.KiteKey = testutil.NewKiteKey().Raw

	// Power up our own kontrol kite for self-contained tests
	kontrol.DefaultPort = 4099
	kntrl := kontrol.New(conf.Copy(), "0.1.0", testkeys.Public, testkeys.Private)
	kntrl.Machines = []string{etcdIp}
	go kntrl.Run()
	<-kntrl.Kite.ServerReadyNotify()

	// Power up kloud kite
	kloudKite = kite.New("kloud", "0.0.1")
	kloudKite.Config = conf.Copy()
	kloudKite.Config.Port = 4002
	kiteURL := &url.URL{Scheme: "http", Host: "localhost:4002", Path: "/kite"}
	_, err := kloudKite.Register(kiteURL)
	if err != nil {
		log.Fatal(err)
	}

	// Add Kloud handlers
	kld := newKloud()
	kloudKite.HandleFunc("build", kld.Build)
	kloudKite.HandleFunc("destroy", kld.Destroy)
	kloudKite.HandleFunc("start", kld.Start)
	kloudKite.HandleFunc("stop", kld.Stop)
	kloudKite.HandleFunc("reinit", kld.Reinit)
	kloudKite.HandleFunc("resize", kld.Resize)
	kloudKite.HandleFunc("event", kld.Event)

	go kloudKite.Run()
	<-kloudKite.ServerReadyNotify()

	user := kite.New("user", "0.0.1")
	user.Config = conf.Copy()

	kloudQuery := &protocol.KontrolQuery{
		Username:    "testuser",
		Environment: conf.Environment,
		Name:        "kloud",
	}
	kites, err := user.GetKites(kloudQuery)
	if err != nil {
		log.Fatal(err)
	}

	// Get the caller
	remote = kites[0]
	if err := remote.Dial(); err != nil {
		log.Fatal(err)
	}
}

// Main VM action tests (build, start, stop, destroy, resize, reinit)

func TestPing(t *testing.T) {
	_, err := remote.Tell("kite.ping")
	if err != nil {
		t.Fatal(err)
	}
}

func TestInvalidMethodsOnUnitialized(t *testing.T) {
	if err := start(machineId0); err == nil {
		t.Error("`start` method can not be called on `uninitialized` machines.")
	}

	if err := stop(machineId0); err == nil {
		t.Error("`stop` method can not be called on `uninitialized` machines.")
	}

	if err := destroy(machineId0); err == nil {
		t.Error("`destroy` method can not be called on `uninitialized` machines.")
	}

	if err := resize(machineId0); err == nil {
		t.Error("`resize` method can not be called on `uninitialized` machines.")
	}

	if err := reinit(machineId0); err == nil {
		t.Error("`reinit` method can not be called on `uninitialized` machines.")
	}
}

func TestBuild(t *testing.T) {
	if err := build(machineId0); err != nil {
		t.Error(err)
	}
}

func TestInvalidMethodsOnRunning(t *testing.T) {
	t.Log("Running invalid methods on a running VM.")
	if err := build(machineId0); err == nil {
		t.Error("`build` method can not be called on `running` machines.")
	}
}

func TestStop(t *testing.T) {
	if err := stop(machineId0); err != nil {
		t.Error(err)
	}
}

func TestInvalidMethodsOnStopped(t *testing.T) {
	t.Log("Running invalid methods on a stopped VM.")
	// run the tests now.
	if err := build(machineId0); err == nil {
		t.Error("`build` method can not be called on `stopped` machines.")
	}

	if err := stop(machineId0); err == nil {
		t.Error("`stop` method can not be called on `stopped` machines.")
	}
}

func TestStart(t *testing.T) {
	if err := start(machineId0); err != nil {
		t.Error(err)
	}
}

func TestResize(t *testing.T) {
	storageWant := 5
	m := GetMachineData(machineId0)
	m.Builder["storage_size"] = storageWant
	SetMachineData(machineId0, m)

	if err := resize(machineId0); err != nil {
		t.Error(err)
	}

	storageGot, err := getAmazonStorageSize(machineId0)
	if err != nil {
		t.Error(err)
	}

	if storageGot != storageWant {
		t.Errorf("Resizing completed but storage sizes do not match. Want: %dGB, Got: %dGB",
			storageWant,
			storageGot,
		)
	}
}

func TestReinit(t *testing.T) {
	if err := reinit(machineId0); err != nil {
		t.Error(err)
	}
}

func TestDestroy(t *testing.T) {
	if err := destroy(machineId0); err != nil {
		t.Error(err)
	}
}

func TestInvalidMethodsOnTerminated(t *testing.T) {
	t.Log("Running invalid methods on a terminated VM.")
	if err := stop(machineId0); err == nil {
		t.Error("`stop` method can not be called on `terminated` machines.")
	}

	if err := start(machineId0); err == nil {
		t.Error("`start` method can not be called on `terminated` machines.")
	}

	if err := destroy(machineId0); err == nil {
		t.Error("`destroy` method can not be called on `terminated` machines.")
	}

	if err := resize(machineId0); err == nil {
		t.Error("`resize` method can not be called on `terminated` machines.")
	}

	if err := reinit(machineId0); err == nil {
		t.Error("`reinit` method can not be called on `terminated` machines.")
	}
}

func build(id string) error {
	buildArgs := &args{
		MachineId: id,
	}

	// inject a generated public key to machine data so build can use it during
	// cloud-init provisioning
	data := GetMachineData(id)
	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return err
	}

	data.Builder["user_ssh_keys"] = []string{publicKey}
	SetMachineData(id, data)

	resp, err := remote.Tell("build", buildArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: buildArgs.MachineId,
			Type:    "build",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running); err != nil {
		return err
	}

	// now try to ssh into the machine with temporary private key we created in
	// the beginning
	newData := GetMachineData(id)

	sshConfig, err := sshutil.SshConfig("root", privateKey)
	if err != nil {
		return err
	}

	log.Printf("Connecting to machine with ip '%s' via ssh\n", newData.IpAddress)
	sshClient, err := sshutil.ConnectSSH(newData.IpAddress+":22", sshConfig)
	if err != nil {
		return err
	}

	output, err := sshClient.StartCommand("whoami")
	if err != nil {
		return err
	}

	if strings.TrimSpace(string(output)) != "root" {
		return fmt.Errorf("Whoami result should be root, got: %s", string(output))
	}

	return nil
}

func destroy(id string) error {
	destroyArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("destroy", destroyArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}
	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: destroyArgs.MachineId,
			Type:    "destroy",
		},
	})

	if err := listenEvent(eArgs, machinestate.Terminated); err != nil {
		return err
	}

	return nil
}

func start(id string) error {
	startArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("start", startArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: startArgs.MachineId,
			Type:    "start",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running); err != nil {
		return err
	}

	return nil
}

func stop(id string) error {
	stopArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("stop", stopArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: stopArgs.MachineId,
			Type:    "stop",
		},
	})

	if err := listenEvent(eArgs, machinestate.Stopped); err != nil {
		return err
	}

	return nil
}

func reinit(id string) error {
	reinitArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("reinit", reinitArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: reinitArgs.MachineId,
			Type:    "reinit",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running); err != nil {
		return err
	}

	return nil
}

func resize(id string) error {
	resizeArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("resize", resizeArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: resizeArgs.MachineId,
			Type:    "resize",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running); err != nil {
		return err
	}

	return nil
}

// listenEvent calls the event method of kloud with the given arguments until
// the desiredState is received. It times out if the desired state is not
// reached in 10 miunuts.
func listenEvent(args kloud.EventArgs, desiredState machinestate.State) error {
	tryUntil := time.Now().Add(time.Minute * 10)
	for {
		resp, err := remote.Tell("event", args)
		if err != nil {
			return err
		}

		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return err
		}

		e := events[0]
		if e.Error != nil {
			return e.Error
		}

		event := e.Event

		if event.Status == desiredState {
			return nil
		}

		if time.Now().After(tryUntil) {
			return fmt.Errorf("Timeout while waiting for state %s", desiredState)
		}

		time.Sleep(2 * time.Second)
		continue // still pending
	}

	return nil
}

func newKloud() *kloud.Kloud {
	testChecker := &TestChecker{}
	testStorage := &TestStorage{}
	testLocker := &TestLocker{}
	testLocker.IdLock = idlock.New()

	var _ kloud.Storage = testStorage
	var _ kloud.Locker = testLocker
	var _ koding.Checker = testChecker

	kld := kloud.New()
	kld.Log = newLogger("kloud", false)
	kld.Locker = testLocker
	kld.Storage = testStorage
	kld.Debug = true

	provider = &koding.Provider{
		Kite: kloudKite,
		Log:  newLogger("koding", false),

		KontrolURL:        conf.KontrolURL,
		KontrolPrivateKey: testkeys.Private,
		KontrolPublicKey:  testkeys.Public,
		Test:              true,
		EC2:               koding.NewEC2Client(),
		DNS:               koding.NewDNSClient("dev.koding.io"), // TODO: Use test.koding.io
		Bucket:            koding.NewBucket("koding-klient", "development/latest"),
		AssigneeName:      "kloud-test",

		KeyName:     keys.DeployKeyName,
		PublicKey:   keys.DeployPublicKey,
		PrivateKey:  keys.DeployPrivateKey,
		PlanChecker: func(_ *kloudprotocol.Machine) (koding.Checker, error) { return testChecker, nil },
		PlanFetcher: func(_ *kloudprotocol.Machine) (koding.Plan, error) { return koding.Free, nil },
	}

	kld.AddProvider("koding", provider)

	return kld
}

func getAmazonStorageSize(machineId string) (int, error) {
	m := GetMachineData(machineId0)

	a, err := provider.NewClient(m)
	if err != nil {
		return 0, err
	}

	instance, err := a.Instance(a.Id())
	if err != nil {
		return 0, err
	}

	if len(instance.BlockDevices) == 0 {
		return 0, fmt.Errorf("fatal error: no block device available")
	}

	// we need in a lot of placages!
	oldVolumeId := instance.BlockDevices[0].VolumeId

	oldVolResp, err := a.Client.Volumes([]string{oldVolumeId}, ec2.NewFilter())
	if err != nil {
		return 0, err
	}

	volSize := oldVolResp.Volumes[0].Size
	currentSize, err := strconv.Atoi(volSize)
	if err != nil {
		return 0, err
	}

	return currentSize, nil
}
