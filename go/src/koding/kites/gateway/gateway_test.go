package gateway_test

import (
	"bytes"
	"fmt"
	"os"
	"testing"
	"time"

	"koding/kites/gateway"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/logging"
)

type Recorder struct {
	Req    *gateway.AuthRequest
	Expire time.Time
}

func (rec *Recorder) Record(cfg *gateway.Config) {
	cfg.AuthFunc = func(req *gateway.AuthRequest) error {
		rec.Req = req
		return nil
	}

	cfg.BeforeFunc = func(t time.Time) bool {
		rec.Expire = t

		return gateway.Before(t)
	}
}

func StartKite(cfg *gateway.Config) (close func()) {
	cfg.Kite = kite.New("gateway", "1.0.0")
	cfg.Kite.Config = config.MustGet()

	gateway.NewServer(cfg)

	go cfg.Kite.Run()
	<-cfg.Kite.ServerReadyNotify()

	cfg.ServerURL = fmt.Sprintf("http://127.0.0.1:%d/kite", cfg.Kite.Port())

	return cfg.Kite.Close
}

func TestGateway_UserBucket(t *testing.T) {
	rec := &Recorder{}
	cfg := &gateway.Config{
		AccessKey:  os.Getenv("GATEWAY_ACCESSKEY"),
		SecretKey:  os.Getenv("GATEWAY_SECRETKEY"),
		Bucket:     "koding-gateway-test",
		AuthExpire: 15 * time.Minute,
		Log:        logging.NewCustom("gateway", true),
	}

	rec.Record(cfg)

	defer StartKite(cfg)()

	ub := gateway.NewUserBucket(cfg)

	p := []byte(time.Now().String())

	if err := ub.Put("time", bytes.NewReader(p)); err != nil {
		t.Fatalf("Put()=%s", err)
	}
}
