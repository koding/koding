package command

import (
	"fmt"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kloud"
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
	bArgs := &kloud.Controller{
		MachineId: *b.id,
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
