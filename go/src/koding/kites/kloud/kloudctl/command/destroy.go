package command

import (
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Destroy struct {
	ids *string
}

func NewDestroy() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("destroy", "Destroy a machine")
		f.action = &Destroy{
			ids: f.String("ids", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (d *Destroy) SingleMachine(id string, k *kite.Client) (string, error) {
	destroyArgs := &KloudArgs{
		MachineId: id,
	}

	resp, err := k.Tell("destroy", destroyArgs)
	if err != nil {
		return "", err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return "", err
	}

	return result.EventId, nil
}

func (d *Destroy) Action(args []string, k *kite.Client) error {
	machines := strings.Split(*d.ids, ",")

	var wg sync.WaitGroup
	for _, id := range machines {
		wg.Add(1)

		go func(id string) {
			defer wg.Done()
			result, err := d.SingleMachine(id, k)
			if err != nil {
				DefaultUi.Error(err.Error())
			} else {
				DefaultUi.Info(fmt.Sprintf("%+v", result))
			}
		}(id)
	}

	DefaultUi.Info(fmt.Sprintf("destroy called for '%d' machines:\n", len(machines)))

	wg.Wait()

	if len(machines) == 1 {
		if flagWatchEvents {
			return watch(k, "destroy", machines[0], defaultPollInterval)
		}
	}

	return nil
}
