package command

import (
	"fmt"
	"time"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Build struct {
	id *string
}

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("build", "Build a machine")
		f.action = &Build{
			id: f.String("id", "", "machine Id to be created"),
		}
		return f, nil
	}
}

func (b *Build) Action(args []string, k *kite.Client) error {
	bArgs := &KloudArgs{
		MachineId: *b.id,
		Username:  flagUsername,
	}

	resp, err := k.TellWithTimeout("build", time.Second*4, bArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	DefaultUi.Info(fmt.Sprintf("%+v", result))

	if flagWatchEvents {
		return watch(k, "build", *b.id, defaultPollInterval)
	}
	return nil
}
