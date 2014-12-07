package command

import (
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Build struct {
	ids *string
}

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("build", "Build a machine")
		f.action = &Build{
			ids: f.String("ids", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (b *Build) SingleMachine(id string, k *kite.Client) (string, error) {
	buildArgs := &KloudArgs{
		MachineId: id,
	}

	resp, err := k.Tell("build", buildArgs)
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

func (b *Build) Action(args []string, k *kite.Client) error {
	machines := strings.Split(*b.ids, ",")

	var wg sync.WaitGroup
	for _, id := range machines {
		wg.Add(1)

		go func(id string) {
			defer wg.Done()
			result, err := b.SingleMachine(id, k)
			if err != nil {
				DefaultUi.Error(err.Error())
			} else {
				DefaultUi.Info(fmt.Sprintf("%+v", result))
			}
		}(id)
	}

	DefaultUi.Info(fmt.Sprintf("build called for '%d' machines:\n", len(machines)))

	wg.Wait()

	if len(machines) == 1 {
		if flagWatchEvents {
			return watch(k, "build", machines[0], defaultPollInterval)
		}
	}

	return nil
}
