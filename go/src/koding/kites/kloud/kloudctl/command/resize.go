package command

import (
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Resize struct {
	ids *string
}

func NewResize() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("resize", "Resize a machine")
		f.action = &Resize{
			ids: f.String("ids", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (r *Resize) SingleMachine(id string, k *kite.Client) (string, error) {
	resizeArgs := &KloudArgs{
		MachineId: id,
	}

	resp, err := k.Tell("resize", resizeArgs)
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

func (r *Resize) Action(args []string, k *kite.Client) error {
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

	DefaultUi.Info(fmt.Sprintf("resize called for '%d' machines:\n", len(machines)))

	wg.Wait()

	if len(machines) == 1 {
		if flagWatchEvents {
			return watch(k, "resize", machines[0], defaultPollInterval)
		}
	}

	return nil
}
