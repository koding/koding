package command

import (
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	"github.com/mitchellh/cli"
)

type Stop struct {
	id *string
}

func NewStop() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("stop", "Stop a machine")
		f.action = &Stop{
			id: f.String("id", "", "Machine id of to be stopped."),
		}
		return f, nil
	}
}

func (s *Stop) Action(args []string, k *kite.Client) error {
	stopArgs := &kloud.Controller{
		MachineId: *s.id,
	}

	resp, err := k.Tell("stop", stopArgs)
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
