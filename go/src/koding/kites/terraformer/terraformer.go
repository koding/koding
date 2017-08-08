// Package terraformer provider bridge between terraformer and application
// without needing the operation over a cli
package terraformer

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"sync"
	"syscall"

	"koding/kites/common"
	"koding/kites/terraformer/kodingcontext"
	"koding/kites/terraformer/storage"

	dogstatsd "github.com/DataDog/datadog-go/statsd"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/logging"
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
	Metrics *dogstatsd.Client

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
	Variables map[string]interface{}
	ContentID string
	TraceID   string
}

// New creates a new terraformer
func New(conf *Config, log logging.Logger) (*Terraformer, error) {
	ls, err := storage.NewFile(conf.LocalStorePath, log)
	if err != nil {
		return nil, fmt.Errorf("error while creating local store: %s", err)
	}

	var rs storage.Interface
	if conf.AWS.Key != "" && conf.AWS.Secret != "" && conf.AWS.Bucket != "" {
		s3, err := storage.NewS3(conf.AWS.Key, conf.AWS.Secret, conf.AWS.Bucket, log)
		if err != nil {
			return nil, fmt.Errorf("error while creating remote store: %s", err)
		}

		rs = s3
	} else {
		remotePath := filepath.Dir(conf.LocalStorePath)
		if conf.AWS.Bucket != "" {
			remotePath = filepath.Join(remotePath, conf.AWS.Bucket)
		} else {
			remotePath = filepath.Join(remotePath, filepath.Base(conf.LocalStorePath)+".remote")
		}

		local, err := storage.NewFile(remotePath, log)
		if err != nil {
			return nil, fmt.Errorf("error while creating remote store on local: %s", err)
		}

		log.Info("no S3 credentials, using local storage: %s", remotePath)

		rs = local
	}

	c, err := kodingcontext.New(ls, rs, log, conf.Debug)
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

// Close closes the embedded properties of terraformer
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

// Wait waits for Terraformer to exit
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
			t.Log.Info("%s signal received, closing terraformer", s)
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

	c, err := t.Context.Get(args.ContentID, args.TraceID)
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

	c, err := t.Context.Get(args.ContentID, args.TraceID)
	if err != nil {
		return nil, err
	}
	defer c.Close()

	// set variables if sent
	c.Variables = args.Variables

	// set content if non-empty
	var content io.Reader
	if args.Content != "" {
		content = strings.NewReader(args.Content)
	}

	return c.Apply(content, destroy)
}

func (t *Terraformer) handleState(r *kite.Request) (interface{}, error) {
	t.rwmu.RLock()
	defer t.rwmu.RUnlock()

	if t.closing {
		return false, errors.New("terraformer is closing")
	}

	return true, nil
}
