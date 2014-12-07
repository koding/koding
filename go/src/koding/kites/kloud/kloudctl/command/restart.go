package command

import (
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Restart struct {
	ids *string
}

func NewRestart() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("restart", "Restart a machine")
		f.action = &Restart{
			ids: f.String("ids", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (r *Restart) SingleMachine(id string, k *kite.Client) (string, error) {
	restartArgs := &KloudArgs{
		MachineId: id,
	}

	resp, err := k.Tell("restart", restartArgs)
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

func (r *Restart) Action(args []string, k *kite.Client) error {
	machines := strings.Split(*r.ids, ",")

	var wg sync.WaitGroup
	for _, id := range machines {
		wg.Add(1)

		go func(id string) {
			defer wg.Done()
			result, err := r.SingleMachine(id, k)
			if err != nil {
				DefaultUi.Error(err.Error())
			} else {
				DefaultUi.Info(fmt.Sprintf("%+v", result))
			}
		}(id)
	}

	DefaultUi.Info(fmt.Sprintf("restart called for '%d' machines:\n", len(machines)))

	wg.Wait()

	if len(machines) == 1 {
		if flagWatchEvents {
			return watch(k, "restart", machines[0], defaultPollInterval)
		}
	}

	return nil
}
