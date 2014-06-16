package command

import (
	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Info struct {
	id *string
}

func NewInfo() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("info", "Show status and information about a machine")
		f.action = &Event{
			id: f.String("id", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (i *Info) Action(args []string, k *kite.Client) error {
	return nil
}
