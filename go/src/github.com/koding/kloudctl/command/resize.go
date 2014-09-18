package command

import (
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	"github.com/mitchellh/cli"
)

type Resize struct {
	id *string
}

func NewResize() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("resize", "Resize a machine")
		f.action = &Resize{
			id: f.String("id", "", "Machine id of to be resized."),
		}
		return f, nil
	}
}

func (r *Resize) Action(args []string, k *kite.Client) error {
	resizeArgs := &kloud.Controller{
		MachineId: *r.id,
		Username:  flagUsername,
	}

	resp, err := k.Tell("resize", resizeArgs)
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
