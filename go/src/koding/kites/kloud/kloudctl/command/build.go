package command

import (
	"fmt"
	"koding/kites/kloud/stack"

	"github.com/mitchellh/cli"
)

type Build struct {
	id         *string
	snapshotId *string
	provider   *string
}

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("build", "Build a machine")
		f.action = &Build{
			id:         f.String("id", "", "Machine Id belonging to the Build"),
			snapshotId: f.String("snapshot", "", "Build the machine from this snapshot"),
			provider:   f.String("provider", "koding", "Kloud provider."),
		}
		return f, nil
	}
}

func (b *Build) Action(args []string) error {
	k, err := kloudClient()
	if err != nil {
		return err
	}

	DefaultUi.Info(fmt.Sprintf("Build called for machine '%s'\n", *b.id))

	resp, err := k.Tell("build", &KloudArgs{
		MachineId:  *b.id,
		SnapshotId: *b.snapshotId,
		Provider:   *b.provider,
	})
	if err != nil {
		return err
	}

	var result stack.ControlResult
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
