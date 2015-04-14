package terraformer

import (
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
)

type Terraformer struct {
	Log logging.Logger

	Metrics *metrics.DogStatsD

	// Enable debug mode
	Debug bool
}

func New() *Terraformer {
	return &Terraformer{}
}

func (t *Terraformer) Apply(r *kite.Request) (interface{}, error) {
	return nil, nil
}

func (t *Terraformer) Destroy(r *kite.Request) (interface{}, error) {
	return nil, nil
}

func (t *Terraformer) Plan(r *kite.Request) (interface{}, error) {
	return nil, nil
}
