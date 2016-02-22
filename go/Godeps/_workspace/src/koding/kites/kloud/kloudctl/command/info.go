package command

import (
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Info struct {
	ids *string
}

func NewInfo() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("info", "Show status and information about a machine")
		f.action = &Info{
			ids: f.String("ids", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (i *Info) SingleMachine(id string, k *kite.Client) (string, error) {
	infoArgs := &KloudArgs{
		MachineId: id,
	}

	resp, err := k.Tell("info", infoArgs)
	if err != nil {
		return "", err
	}

	var result kloud.InfoResponse
	err = resp.Unmarshal(&result)
	if err != nil {
		return "", err
	}

	return result.State, nil
}

func (i *Info) Action(args []string, k *kite.Client) error {
	machines := strings.Split(*i.ids, ",")

	var wg sync.WaitGroup
	for _, id := range machines {
		wg.Add(1)
		go func(id string) {
			defer wg.Done()
			result, err := i.SingleMachine(id, k)
			if err != nil {
				DefaultUi.Error(err.Error())
			} else {
				DefaultUi.Info(fmt.Sprintf("%s: %s", id, result))
			}
		}(id)
	}

	DefaultUi.Info(fmt.Sprintf("info called for '%d' machines:\n", len(machines)))
	wg.Wait()
	return nil
}
