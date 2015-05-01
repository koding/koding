// Package terraformer provider bridge between terraformer and application
// without needing the operation over a cli
package terraformer

import (
	"errors"
	"fmt"
	"koding/kites/terraformer/kodingcontext"
	"koding/kites/terraformer/storage"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"

	"koding/kites/common"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
)

var (
	// Name holds the worker name
	Name = "terraformer"

	// Version holds the version of the worker
	Version = "0.0.1"
)

// Terraformer holds the required parameter for terraformer worker context
type Terraformer struct {
	// Log is a specialized log system for terraform
	Log logging.Logger

	// Metrics holds the metric aggregator
	Metrics *metrics.DogStatsD

	// Enable debug mode
	Debug bool

	// Context holds the initial context, all usages should get from it
	Context kodingcontext.Context

	// Store app runtime config
	Config *Config

	closeChan chan struct{} // To signal when terraformer is closing

	closing bool
	rwmu    sync.RWMutex
}

// TerraformRequest is a helper struct for terraformer kite requests
type TerraformRequest struct {
	Content   string
	Variables map[string]string
	ContentID string
}

// New creates a new terraformer
func New(conf *Config, log logging.Logger) (*Terraformer, error) {
	ls, err := storage.NewFile(conf.LocalStorePath)
	if err != nil {
		return nil, fmt.Errorf("err while creating local store %s", err)
	}

	rs, err := storage.NewS3(conf.AWS.Key, conf.AWS.Secret, conf.AWS.Bucket)
	if err != nil {
		return nil, fmt.Errorf("err while creating remote store %s", err)
	}

	c, err := kodingcontext.New(ls, rs)
	if err != nil {
		return nil, err
	}

	t := &Terraformer{
		Log:       log,
		Metrics:   common.MustInitMetrics(Name),
		Debug:     conf.Debug,
		Context:   c,
		Config:    conf,
		closeChan: make(chan struct{}),
	}

	t.handleSignals()

	return t, nil
}

// Close closes the embeded properties of terraformer
func (t *Terraformer) Close() error {
	t.rwmu.Lock()
	if t.closing {
		defer t.rwmu.Unlock()
		return errors.New("already closing")
	}
	// mark terraformer as closing and stop accepting new requests
	t.closing = true
	t.rwmu.Unlock()

	var err error
	if t.Context != nil {
		err = t.Context.Shutdown()
		if err != nil {
			t.Log.Critical("err while shutting down context %s", err.Error())
		}
	}

	close(t.closeChan)

	// clean up global vars
	kodingcontext.Close()

	return err
}

// Wait wait for Terraformer to exit
func (t *Terraformer) Wait() error {
	<-t.closeChan // wait for exit
	return nil
}

func (t *Terraformer) handleSignals() {
	go func() {
		signalCh := make(chan os.Signal, 1)
		signal.Notify(signalCh)

		s := <-signalCh
		signal.Stop(signalCh)
		switch s {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGKILL:
			t.Log.Info("%s signal recieved, closing terraformer", s)
			t.Close()
		}
	}()
}

// Plan provides a kite call for plan operation
func (t *Terraformer) Plan(r *kite.Request) (interface{}, error) {
	args := TerraformRequest{}
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	c, err := t.Context.Get(args.ContentID)
	if err != nil {
		return nil, err
	}
	defer c.Close()

	// set variables if sent
	c.Variables = args.Variables

	destroy := false
	return c.Plan(strings.NewReader(args.Content), destroy)
}

// Apply provides a kite call for apply operation
func (t *Terraformer) Apply(r *kite.Request) (interface{}, error) {
	destroy := false
	return t.apply(r, destroy)
}

// Destroy provides a kite call for destroy operation
func (t *Terraformer) Destroy(r *kite.Request) (interface{}, error) {
	destroy := true
	return t.apply(r, destroy)
}

func (t *Terraformer) apply(r *kite.Request, destroy bool) (*terraform.State, error) {
	args := TerraformRequest{}
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	c, err := t.Context.Get(args.ContentID)
	if err != nil {
		return nil, err
	}
	defer c.Close()

	// set variables if sent
	c.Variables = args.Variables

	return c.Apply(strings.NewReader(args.Content), destroy)
}

func (t *Terraformer) handleState(r *kite.Request) (interface{}, error) {
	t.rwmu.RLock()
	defer t.rwmu.RUnlock()

	if t.closing {
		return false, errors.New("terraformer is closing")
	}

	return true, nil
}
