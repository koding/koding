package command

import (
	"fmt"

	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Info struct {
	id *string
}

func NewInfo() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("info", "Show status and information about a machine")
		f.action = &Info{
			id: f.String("id", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (i *Info) Action(args []string, k *kite.Client) error {
	infoArgs := &KloudArgs{
		MachineId: *i.id,
		Username:  flagUsername,
	}

	resp, err := k.Tell("info", infoArgs)
	if err != nil {
		return err
	}

	var result protocol.InfoArtifact
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	DefaultUi.Info(fmt.Sprintf("%+v", result))

	if flagWatchEvents {
		return watch(k, "info", *i.id, defaultPollInterval)
	}
	return nil
}
