package gateway_test

import (
	"fmt"
	"time"

	"koding/kites/gateway"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kitetest"
)

// DefaultKeyPair
var DefaultKeyPair = must(kitetest.GenerateKeyPair())

// Driver
type Driver struct {
	KeyPair *kitetest.KeyPair
}

func (*Driver) AuthFunc(cfg *gateway.Config) <-chan *gateway.AuthRequest {
	ch := make(chan *gateway.AuthRequest, 1)

	cfg.AuthFunc = func(req *gateway.AuthRequest) error {
		ch <- req
		return nil
	}

	return ch
}

func (*Driver) BeforeFunc(cfg *gateway.Config) <-chan time.Time {
	ch := make(chan time.Time, 1)

	cfg.BeforeFunc = func(t time.Time) bool {
		ch <- t

		return gateway.Before(t)
	}

	return ch
}

func (s *Driver) Kite(cfg *gateway.Config, username string) *gateway.Config {
	key, err := kitetest.GenerateKiteKey(&kitetest.KiteKey{Username: username}, s.keyPair())
	if err != nil {
		panic(err)
	}

	cfgCopy := *cfg
	cfgCopy.Kite = kite.New(username, "0.0.1")
	cfgCopy.Kite.Config = &config.Config{
		Username:    username,
		Environment: "test",
		Region:      "test",
		KontrolKey:  string(s.keyPair().Public),
		KiteKey:     key.Raw,
	}

	return &cfgCopy
}

func (s *Driver) Server(cfg *gateway.Config) (teardown func()) {
	kiteCfg := s.Kite(cfg, "gateway")

	gateway.NewServer(kiteCfg)

	go kiteCfg.Kite.Run()
	<-kiteCfg.Kite.ServerReadyNotify()

	cfg.ServerURL = fmt.Sprintf("http://127.0.0.1:%d/kite", kiteCfg.Kite.Port())

	return kiteCfg.Kite.Close
}

func (s *Driver) keyPair() *kitetest.KeyPair {
	if s.KeyPair != nil {
		return s.KeyPair
	}

	return DefaultKeyPair
}

func must(kp *kitetest.KeyPair, err error) *kitetest.KeyPair {
	if err != nil {
		panic(err)
	}

	return kp
}
