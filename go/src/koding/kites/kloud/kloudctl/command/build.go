package command

import (
	"fmt"
	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Build struct {
	id         *string
	snapshotId *string
}

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("build", "Build a machine")
		f.action = &Build{
			id:         f.String("id", "", "Machine Id belonging to the Build"),
			snapshotId: f.String("snapshot", "", "Build the machine from this snapshot"),
		}
		return f, nil
	}
}

func (b *Build) Action(args []string, k *kite.Client) error {
	DefaultUi.Info(fmt.Sprintf("Build called for machine '%s'\n", *b.id))

	resp, err := k.Tell("build", &KloudArgs{
		MachineId:  *b.id,
		SnapshotId: *b.snapshotId,
		Provider:   "koding",
	})
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
		return watch(k, "build", *b.id, defaultPollInterval)
	}

	return nil
}
