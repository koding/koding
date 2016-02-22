package command

import "github.com/mitchellh/cli"

type Snapshot struct {
	id         *string
	snapshotId *string
}

func NewDeleteSnapshot() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("deleteSnapshot", "Delete a snapshot")
		f.action = &Snapshot{
			id:         f.String("ids", "", "Machine Id belonging to the Snapshot"),
			snapshotId: f.String("snapshot", "", "Snapshot to be deleted"),
		}
		return f, nil
	}
}

func (s *Snapshot) Action(args []string) error {
	k, err := kloudClient()
	if err != nil {
		return err
	}
	_, err = k.Tell("deleteSnapshot", &KloudArgs{
		MachineId:  *s.id,
		SnapshotId: *s.snapshotId,
	})

	return err
}
