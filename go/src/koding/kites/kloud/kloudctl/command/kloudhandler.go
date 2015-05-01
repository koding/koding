package command

import (
	"fmt"
	"math/rand"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

// used to authenticate with Kloud directly
const KloudSecretKey = "J7suqUXhqXeiLchTrBDvovoJZEBVPxncdHyHCYqnGfY4HirKCe"

func init() {
	rand.Seed(time.Now().UTC().UnixNano())
}

// KloudArgs is used as argument that is sent to kloud
type KloudArgs struct {
	MachineId  string `json:"machineId"`
	SnapshotId string `json:"snapshotId"`
	Username   string `json:"username"`
	Provider   string `json:"provider"`
}

type Actioner interface {
	Action([]string, *kite.Client) error
}

type ActionFunc func(args []string, k *kite.Client) error

func (a ActionFunc) Action(args []string, k *kite.Client) error {
	return a(args, k)
}

func kloudWrapper(args []string, actioner Actioner) error {
	k, err := kloudClient()
	if err != nil {
		DefaultUi.Error(err.Error())
		return err
	}

	err = actioner.Action(args, k)
	if err != nil {
		DefaultUi.Error(err.Error())
		return err
	}

	return nil

}

func kloudClient() (*kite.Client, error) {
	k := kite.New("kloudctl", "0.0.1")
	c, err := config.Get()
	if err != nil {
		return nil, err
	}

	k.Config = c
	k.Config.Transport = config.XHRPolling
	k.SetLogLevel(kite.WARNING)

	remoteKite := k.NewClient(flagKloudAddr)
	remoteKite.Auth = &kite.Auth{
		Type: "kloudctl",
		Key:  KloudSecretKey,
	}

	if err := remoteKite.DialTimeout(time.Second * 10); err != nil {
		DefaultUi.Output(fmt.Sprintf("Connecting failed to %s: %s", flagKloudAddr, err))
		return nil, err
	}

	return remoteKite, nil
}
