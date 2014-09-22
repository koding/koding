package main

import (
	"fmt"
	"log"
	"net/url"
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
)

var (
	kloudKite *kite.Kite
	kld       *kloud.Kloud
	remote    *kite.Client
	conf      *config.Config
)

const machineId = "koding_id0"

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

func TestPing(t *testing.T) {
	_, err := remote.Tell("kite.ping")
	if err != nil {
		t.Fatal(err)
	}
}

func TestBuild(t *testing.T) {
	if err := build(machineId); err != nil {
		t.Error(err)
	}
}

func TestStop(t *testing.T) {
	if err := stop(machineId); err != nil {
		t.Error(err)
	}
}

func TestStart(t *testing.T) {
	if err := start(machineId); err != nil {
		t.Error(err)
	}
}

func TestReinit(t *testing.T) {
	if err := reinit(machineId); err != nil {
		t.Error(err)
	}
}

func TestDestroy(t *testing.T) {
	if err := destroy(machineId); err != nil {
		t.Error(err)
	}
}

func build(id string) error {
	buildArgs := &args{
		MachineId: id,
	}

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

	provider := &koding.Provider{
		Kite: kloudKite,
		Log:  newLogger("koding", false),

		KontrolURL:        conf.KontrolURL,
		KontrolPrivateKey: testkeys.Private,
		KontrolPublicKey:  testkeys.Public,
		Bucket:            koding.NewBucket("koding-kites", "klient/development/latest"),
		Test:              true,
		HostedZone:        "dev.koding.io", // TODO: Use test.koding.io
		AssigneeName:      "kloud-test",

		KeyName:     keys.DeployKeyName,
		PublicKey:   keys.DeployPublicKey,
		PrivateKey:  keys.DeployPrivateKey,
		PlanChecker: func(_ *kloudprotocol.Machine) (koding.Checker, error) { return testChecker, nil },
	}

	kld.AddProvider("koding", provider)

	return kld
}
