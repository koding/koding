package command

import (
	"fmt"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Reinit struct {
	id *string
}

func NewReinit() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("reinit", "Reinitialize a machine")
		f.action = &Reinit{
			id: f.String("id", "", "Machine id of to be reinitialized."),
		}
		return f, nil
	}
}

func (r *Reinit) Action(args []string, k *kite.Client) error {
	reinitArgs := &KloudArgs{
		MachineId: *r.id,
		Username:  flagUsername,
	}

	resp, err := k.Tell("reinit", reinitArgs)
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
		return watch(k, "reinit", *r.id, defaultPollInterval)
	}
	return nil
}
