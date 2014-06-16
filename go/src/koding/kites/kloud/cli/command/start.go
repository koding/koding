package command

import (
	"fmt"
	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Start struct {
	id *string
}

func NewStart() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("start", "Start a machine")
		f.action = &Start{
			id: f.String("id", "", "Machine id of to be started."),
		}
		return f, nil
	}
}

func (s *Start) Action(args []string, k *kite.Client) error {
	startArgs := &kloud.Controller{
		MachineId: *s.id,
	}

	resp, err := k.Tell("start", startArgs)
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
