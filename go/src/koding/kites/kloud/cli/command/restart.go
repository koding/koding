package command

import (
	"fmt"
	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Restart struct {
	id *string
}

func NewRestart() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("restart", "Restart a machine")
		f.action = &Restart{
			id: f.String("id", "", "Machine id of to be restarted."),
		}
		return f, nil
	}
}

func (r *Restart) Action(args []string, k *kite.Client) error {
	restartArgs := &kloud.Controller{
		MachineId: *r.id,
	}

	resp, err := k.Tell("restart", restartArgs)
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
