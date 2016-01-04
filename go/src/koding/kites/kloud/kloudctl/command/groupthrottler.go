package command

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"os/signal"
	"time"

	"koding/kites/kloud/kloud"

	"github.com/hashicorp/go-multierror"
	"golang.org/x/net/context"
)

type Stage struct {
	Name     string    `json:"name,omitempty"`
	Start    time.Time `json:"start,omitempty"`
	Progress int       `json:"progress,omitempty"`
}

type Status struct {
	MachineID    string    `json:"machineId,omitempty"`
	MachineLabel string    `json:"machineLabel,omitempty"`
	Start        time.Time `json:"start,omitempty"`
	End          time.Time `json:"end,omitempty"`
	Stages       []Stage   `json:"stages,omitempty"`
	Err          error     `json:"err,omitempty"`
}

type Item interface {
	ID() string
	Label() string
}

// ErrSkipWatch is used to skip waiting for kloud events.
var ErrSkipWatch = errors.New("skipped waiting for kloud events")

// ProcessFunc processes a single item.
type ProcessFunc func(context.Context, Item) error

// GroupThrottler is used for throttling group of kloud API calls.
type GroupThrottler struct {
	Name    string      // command name to wait on kloud progress
	Process ProcessFunc // processes a single item

	throttle int
	output   string
}

func (gt *GroupThrottler) RegisterFlags(f *flag.FlagSet) {
	f.IntVar(&gt.throttle, "t", 0, "Throttling - max number of machines to be concurrently created.")
	f.StringVar(&gt.output, "o", "", "File where list of statuses for each build will be written.")
}

func (gt *GroupThrottler) RunItems(ctx context.Context, items []Item) error {
	itemsCh := make(chan Item)
	done := make(chan *Status, len(items))
	cancel := make(chan struct{})

	if gt.throttle == 0 {
		gt.throttle = len(items)
	}

	// Cancel processing on signal.
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt, os.Kill)
	go func() {
		var canceled bool
		for range ch {
			if !canceled {
				close(cancel)
				canceled = true
			}
		}
	}()

	// Process items.
	for i := 0; i < gt.throttle; i++ {
		go func() {
			for item := range itemsCh {
				msg := fmt.Sprintf("Requesting to process %q", item.Label())
				DefaultUi.Info(msg)

				// Early check if processing was canceled to not start
				// actual processing if it's not needed.
				select {
				case <-cancel:
					done <- &Status{
						MachineLabel: item.Label(),
						Err:          errors.New("processing was cancelled"),
					}
				default:
				}

				// Start processing on another goroutine so it can
				// be interrupted.
				ch := make(chan *Status)
				go func() {
					ch <- gt.processAndWatch(ctx, item)
				}()
				select {
				case <-cancel:
					done <- &Status{
						MachineLabel: item.Label(),
						Err:          errors.New("processing was cancelled"),
					}
				case s := <-ch:
					done <- s
				}
			}
		}()
	}

	// Keep sending items for processing.
	go func() {
		for _, item := range items {
			itemsCh <- item
		}
	}()

	// Read processing results and produce simple stats.
	var errs *multierror.Error
	var avg, max time.Duration
	var min = time.Hour
	var statuses = make([]*Status, len(items))

	for i := range statuses {
		s := <-done
		dur := s.End.Sub(s.Start)

		// Compute min, max and average processing times.
		avg += dur
		if dur < min {
			min = dur
		}
		if dur > max {
			max = dur
		}

		if s.Err == ErrSkipWatch {
			s.Err = nil
		}

		// Handle error if any.
		if s.Err != nil {
			err := fmt.Errorf("Error processing %q (%q): %s", s.MachineLabel, s.MachineID, s.Err)
			DefaultUi.Error(err.Error())
			errs = multierror.Append(errs, err)
		} else {
			msg := fmt.Sprintf("Processing %q (%q) finished in %s.", s.MachineLabel, s.MachineID, dur)
			DefaultUi.Info(msg)
		}

		statuses[i] = s
	}

	avg = avg / time.Duration(len(items))
	DefaultUi.Info(fmt.Sprintf("Processing times: avg=%s, min=%s, max=%s", avg, min, max))

	if err := gt.writeStatuses(statuses); err != nil {
		errs = multierror.Append(errs, err)
	}

	return errs.ErrorOrNil()
}

func (gt *GroupThrottler) processAndWatch(ctx context.Context, item Item) *Status {
	k, _ := fromContext(ctx)
	start := time.Now()
	var stages []Stage
	newStatus := func(err error) *Status {
		return &Status{
			MachineID:    item.ID(),
			MachineLabel: item.Label(),
			Start:        start,
			Stages:       stages,
			End:          time.Now(),
			Err:          err,
		}
	}
	if err := gt.Process(ctx, item); err != nil {
		return newStatus(err)
	}
	req := kloud.EventArgs{{
		Type:    gt.Name,
		EventId: item.ID(),
	}}
	var last Stage
	for {
		resp, err := k.Tell("event", req)
		if err != nil {
			return newStatus(err)
		}
		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return newStatus(err)
		}
		if len(events) == 0 || events[0].Event == nil {
			return newStatus(errors.New("empty event response"))
		}
		if events[0].Event.Message != last.Name || events[0].Event.Percentage != last.Progress {
			last = Stage{
				Name:     events[0].Event.Message,
				Start:    events[0].Event.TimeStamp,
				Progress: events[0].Event.Percentage,
			}
			stages = append(stages, last)
		}
		if s := events[0].Event.Error; s != "" {
			return newStatus(errors.New(s))
		}
		if events[0].Event.Percentage == 100 {
			return newStatus(nil)
		}
		time.Sleep(defaultPollInterval)
	}
}

func (gt *GroupThrottler) writeStatuses(s []*Status) (err error) {
	var f *os.File
	if gt.output == "" {
		f, err = ioutil.TempFile("", "kloudctl")
	} else {
		f, err = os.OpenFile(gt.output, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, 0755)
	}
	if err != nil {
		return err
	}
	defer f.Close()
	err = nonil(json.NewEncoder(f).Encode(s), f.Sync(), f.Close())
	if err != nil {
		return err
	}
	DefaultUi.Info(fmt.Sprintf("Status written to %q", f.Name()))
	return nil
}
