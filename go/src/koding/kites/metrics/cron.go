package metrics

import (
	"koding/kites/kloud/metrics"
	"time"

	"github.com/koding/logging"
)

type kloudKite interface {
	Call(method string, req, resp interface{}) error
}

// StartCron starts klient metrics publisher.
func StartCron(kloud kloudKite, log logging.Logger) {
	for range time.NewTicker(time.Second * 3).C {
		m, err := New("kd")
		if err != nil {
			log.Error(err.Error())
			continue
		}

		if err := m.Process(func(res [][]byte) error {
			if len(res) == 0 {
				log.Debug("skipping publishing, 0 elements")
			}
			req := &metrics.PublishRequest{
				Data: metrics.GzippedPayload(res),
			}
			var resp interface{}

			if err := kloud.Call("metrics.publish", req, resp); err != nil {
				log.Error(err.Error())
				return err
			}

			return nil
		}); err != nil {
			log.Error(err.Error())
		}

		if err := m.Close(); err != nil {
			log.Error(err.Error())
		}
	}
}
