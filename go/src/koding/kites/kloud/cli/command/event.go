package command

import (
	"errors"
	"fmt"
	"koding/kites/kloud/kloud"
	"strings"
	"time"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Event struct {
	id        *string
	eventType *string
	event     *string
	interval  *time.Duration
}

func NewEvent() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("event", "Track an event")
		f.action = &Event{
			id:        f.String("id", "", "Event id to track"),
			eventType: f.String("type", "", "Event type, for example: build"),
			event:     f.String("event", "", "Event is the same as id+type"),
			interval:  f.Duration("interval", time.Second*4, "Polling interval"),
		}
		return f, nil
	}
}

func (e *Event) Action(args []string, k *kite.Client) error {
	id := *e.id
	eventType := *e.eventType

	if *e.event != "" {
		splitted := strings.Split(*e.event, "-")
		if len(splitted) != 2 {
			return fmt.Errorf("Incoming event data is malformed %v", *e.event)
		}

		id = splitted[0]
		eventType = splitted[1]
	} else {
		if *e.id == "" {
			return errors.New("id flag is empty")
		}

		if *e.eventType == "" {
			return errors.New("type flag is empty")
		}

		id = *e.id
		eventType = *e.id

	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: id,
			Type:    eventType,
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

		DefaultUi.Info(fmt.Sprintf("%+v", events[0]))
		time.Sleep(*e.interval)
		continue // still pending
	}

	return nil
}
