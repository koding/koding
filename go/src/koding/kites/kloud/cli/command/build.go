package command

import (
	"fmt"
	"time"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Build struct {
	machineId *string
}

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("build", "Build a machine")
		f.action = &Build{
			machineId: f.String("machine", "", "machine Id to be created"),
		}
		return f, nil
	}
}

func (b *Build) Action(args []string, k *kite.Client) error {
	bArgs := &kloud.Controller{
		MachineId: *b.machineId,
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
	return nil
}
