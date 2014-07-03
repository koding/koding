package command

import (
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	"github.com/mitchellh/cli"
)

type Destroy struct {
	id *string
}

func NewDestroy() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("destroy", "Destroy a machine")
		f.action = &Destroy{
			id: f.String("id", "", "Machine id of to be destroyed."),
		}
		return f, nil
	}
}

func (d *Destroy) Action(args []string, k *kite.Client) error {
	destroyArgs := &kloud.Controller{
		MachineId: *d.id,
	}

	resp, err := k.Tell("destroy", destroyArgs)
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
