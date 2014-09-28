package command

import (
	"fmt"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
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
	destroyArgs := &KloudArgs{
		MachineId: *d.id,
		Username:  flagUsername,
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
