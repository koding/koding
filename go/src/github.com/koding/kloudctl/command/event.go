package command

import (
	"fmt"
	"strings"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	"github.com/mitchellh/cli"
)

type Event struct {
	event    *string
	interval *time.Duration
}

func NewEvent() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("event", "Track an event")
		f.action = &Event{
			event:    f.String("id", "", "Event id to be tracked."),
			interval: f.Duration("interval", time.Second*4, "Polling interval, by default 4 seconds"),
		}
		return f, nil
	}
}

func (e *Event) Action(args []string, k *kite.Client) error {
	// args[0] contains the build event in form of "build-123456"
	splitted := strings.Split(*e.event, "-")
	if len(splitted) != 2 {
		return fmt.Errorf("Incoming event data is malformed %v", *e.event)
	}

	eventType := splitted[0]
	id := splitted[1]

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			Type:    eventType,
			EventId: id,
		},
	})

	for {
		resp, err := k.Tell("event", eArgs)
		if err != nil {
			return err
		}

		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return err
		}

		DefaultUi.Info(fmt.Sprintf("%s ==> %s [Status: %s Percentage: %d]",
			fmt.Sprint(time.Now())[:19],
			events[0].Event.Message,
			events[0].Event.Status,
			events[0].Event.Percentage,
		))

		time.Sleep(*e.interval)
		continue // still pending
	}

	return nil
}
