package command

import (
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Stop struct {
	ids *string
}

func NewStop() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("stop", "Stop a machine")
		f.action = &Stop{
			ids: f.String("ids", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (s *Stop) SingleMachine(id string, k *kite.Client) (string, error) {
	stop := &KloudArgs{
		MachineId: id,
	}

	resp, err := k.Tell("stop", stop)
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

func (s *Stop) Action(args []string, k *kite.Client) error {
	machines := strings.Split(*s.ids, ",")

	var wg sync.WaitGroup
	for _, id := range machines {
		wg.Add(1)

		go func(id string) {
			defer wg.Done()
			result, err := s.SingleMachine(id, k)
			if err != nil {
				DefaultUi.Error(err.Error())
			} else {
				DefaultUi.Info(fmt.Sprintf("%+v", result))
			}
		}(id)
	}

	DefaultUi.Info(fmt.Sprintf("stop called for '%d' machines:\n", len(machines)))

	wg.Wait()

	if len(machines) == 1 {
		if flagWatchEvents {
			return watch(k, "stop", machines[0], defaultPollInterval)
		}
	}

	return nil
}
