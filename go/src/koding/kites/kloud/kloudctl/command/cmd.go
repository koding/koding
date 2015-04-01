package command

import (
	"fmt"
	"koding/kites/kloud/kloud"
	"strings"
	"sync"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

const batchLimit = 100

type Cmd struct {
	command string
	ids     *string
}

func NewCmd(command string) cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag(command, fmt.Sprintf("%s a machine", command))
		f.action = &Cmd{
			command: command,
			ids:     f.String("ids", "", "Machine id of information being showed."),
		}
		return f, nil
	}
}

func (c *Cmd) SingleMachine(id string, k *kite.Client) (string, error) {
	resp, err := k.Tell(c.command, &KloudArgs{
		MachineId: id,
		Provider: "koding",
	})
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

func (c *Cmd) Action(args []string, k *kite.Client) error {
	machines := strings.Split(*c.ids, ",")

	if len(machines) > batchLimit {
		return fmt.Errorf("maximum batch size is '%d'. You have '%d'", batchLimit, len(machines))
	}

	var wg sync.WaitGroup
	for _, id := range machines {
		wg.Add(1)

		go func(id string) {
			defer wg.Done()
			result, err := c.SingleMachine(id, k)
			if err != nil {
				DefaultUi.Error(err.Error())
			} else {
				DefaultUi.Info(fmt.Sprintf("%+v", result))
			}
		}(id)
	}

	DefaultUi.Info(fmt.Sprintf("%s called for '%d' machines:\n", c.command, len(machines)))

	wg.Wait()

	if len(machines) == 1 {
		if flagWatchEvents {
			return watch(k, c.command, machines[0], defaultPollInterval)
		}
	}

	return nil
}
