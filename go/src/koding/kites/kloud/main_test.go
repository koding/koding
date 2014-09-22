package main

import (
	"fmt"
	_ "io/ioutil"
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
	kldprotocol "koding/kites/kloud/protocol"
)

var (
	k      *kite.Kite
	kld    *kloud.Kloud
	remote *kite.Client
	conf   *config.Config
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
	kon := kontrol.New(conf.Copy(), "0.1.0", testkeys.Public, testkeys.Private)
	go kon.Run()
	<-kon.Kite.ServerReadyNotify()

	// Power up kloud kite
	k = kite.New("kloud", "0.0.1")
	k.Config = conf.Copy()
	k.Config.Port = 4002
	kiteURL := &url.URL{Scheme: "http", Host: "localhost:4002", Path: "/kite"}
	_, err := k.Register(kiteURL)
	if err != nil {
		log.Fatal(err)
	}

	// Add Kloud handlers
	kld := newKloud()
	k.HandleFunc("build", kld.Build)
	k.HandleFunc("destroy", kld.Destroy)
	k.HandleFunc("event", kld.Event)

	go k.Run()
	<-k.ServerReadyNotify()

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
	if err := build(); err != nil {
		t.Error(err)
	}

}

func TestStop(t *testing.T) {
	if err := stop(); err != nil {
		t.Error(err)
	}
}

func TestStart(t *testing.T) {
	if err := start(); err != nil {
		t.Error(err)
	}
}

func TestDestroy(t *testing.T) {
	if err := destroy(); err != nil {
		t.Error(err)
	}
}

func build() error {
	bArgs := &args{
		MachineId: "koding_id0",
	}

	resp, err := remote.Tell("build", bArgs)
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
			EventId: bArgs.MachineId,
			Type:    "build",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running); err != nil {
		return err
	}

	return nil
}

func destroy() error {
	bArgs := &args{
		MachineId: "koding_id0",
	}

	resp, err := remote.Tell("destroy", bArgs)
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
			EventId: bArgs.MachineId,
			Type:    "destroy",
		},
	})

	if err := listenEvent(eArgs, machinestate.Stopped); err != nil {
		return err
	}

	return nil
}

func start() error {
	bArgs := &args{
		MachineId: "koding_id0",
	}

	resp, err := remote.Tell("start", bArgs)
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
			EventId: bArgs.MachineId,
			Type:    "start",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running); err != nil {
		return err
	}

	return nil
}

func stop() error {
	bArgs := &args{
		MachineId: "koding_id0",
	}

	resp, err := remote.Tell("stop", bArgs)
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
			EventId: bArgs.MachineId,
			Type:    "stop",
		},
	})

	if err := listenEvent(eArgs, machinestate.Stopped); err != nil {
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

type TestProvider struct {
	koding.Provider
}

func (tp *TestProvider) PlanChecker(m *kldprotocol.Machine) (koding.Checker, error) {
	println("************* planchecker called")
	return &TestChecker{}, nil
}

func newKloud() *kloud.Kloud {

	testStorage := &TestStorage{}
	testLocker := &TestLocker{}
	testLocker.IdLock = idlock.New()

	var _ kloud.Storage = testStorage
	var _ kloud.Locker = testLocker

	kld := kloud.New()
	kld.Log = newLogger("kloud", true)
	kld.Locker = testLocker
	kld.Storage = testStorage
	kld.Debug = true

	provider := &TestProvider{
		koding.Provider{
			Kite: k,
			Log:  newLogger("koding", true),

			// KontrolURL:        conf.KontrolURL,
			KontrolURL:        "http://koding-ibrahim.ngrok.com/kite",
			KontrolPrivateKey: testkeys.Private,
			KontrolPublicKey:  testkeys.Public,
			Bucket:            koding.NewBucket("koding-kites", "klient/development/latest"),
			Test:              true,
			HostedZone:        "dev.koding.io", // TODO: Use test.koding.io
			AssigneeName:      "kloud-test",

			KeyName:    keys.DeployKeyName,
			PublicKey:  keys.DeployPublicKey,
			PrivateKey: keys.DeployPrivateKey,
		},
	}

	kld.AddProvider("koding", provider)

	return kld
}
