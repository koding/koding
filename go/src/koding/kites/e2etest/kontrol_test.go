package e2etest

import (
	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
)

type Kontrol struct {
	*kontrol.Kontrol
}

func NewKontrol() Kontrol {
	cfg := Test.Kontrol.Copy()
	psqlCfg := Test.Postgres

	kntrl := kontrol.New(cfg, "0.1.0")
	if Test.Debug {
		kntrl.Kite.SetLogLevel(kite.DEBUG)
	}
	p := kontrol.NewPostgres(&psqlCfg, kntrl.Kite.Log)
	kntrl.SetKeyPairStorage(p)
	kntrl.SetStorage(p)
	kntrl.AddKeyPair("", Test.pemPublic, Test.pemPrivate)
	return Kontrol{Kontrol: kntrl}
}

func (k Kontrol) Start() {
	go k.Kontrol.Run()
	<-k.Kontrol.Kite.ServerReadyNotify()
}
