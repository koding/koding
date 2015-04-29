// Package terraformer provider bridge between terraformer and application
// without needing the operation over a cli
package terraformer

import (
	"fmt"
	"koding/kites/terraformer/kodingcontext"
	"koding/kites/terraformer/storage"
	"strings"

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

	// Context holds the initial context, all usages should clone it
	Context *kodingcontext.Context

	// Store app runtime config
	Config *Config
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

	return &Terraformer{
		Log:     log,
		Metrics: common.MustInitMetrics(Name),
		Debug:   conf.Debug,
		Context: c,
		Config:  conf,
	}, nil
}

// Close closes the embeded properties of terraformer
func (t *Terraformer) Close() error {
	if t.Context == nil {
		return nil
	}

	return t.Context.Close()
}

// Kite creates a new Terraformer Kite communication layer
func (t *Terraformer) Kite() (*kite.Kite, error) {
	return t.newKite(t.Config)
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
