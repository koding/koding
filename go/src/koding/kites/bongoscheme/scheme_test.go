package bongoscheme

import (
	"encoding/json"
	"log"
	"testing"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
)

var bongoKite *kite.Kite

func createKite() *kite.Kite {
	k := kite.New("bongo", "0.0.1")

	k.Config = config.MustGet()
	k.Config.Username = "kite"
	k.Config.Port = 9999
	k.Config.Environment = "unknown"

	k.HandleFunc("bongo", func(r *kite.Request) (interface{}, error) {
		m := r.Args.One().MustMap()

		res, err := json.Marshal(m)
		if err != nil {
			return nil, err
		}

		return string(res), nil
	}).DisableAuthentication()

	go k.Run()
	<-k.ServerReadyNotify()

	if err := k.RegisterForever(k.RegisterURL(true)); err != nil {
		log.Fatalln(err)
	}
	// time.Sleep(time.Second * 30)
	return k
}

func withBongo(f func(b *BongoKite)) error {
	if bongoKite == nil {
		bongoKite = createKite()
	}

	// we could give any kite into New function
	b, err := New(bongoKite, &protocol.KontrolQuery{
		Username:    "kite",
		Name:        "bongo",
		Environment: "unknown",
	})

	if err != nil {
		return err
	}

	// do not leak bongo kites
	defer b.Close()
	f(b)

	return nil
}

func TestCallingStaticFunc(t *testing.T) {
	err := withBongo(func(b *BongoKite) {
		res, err := b.Model("JAccount").Static().Func("one").Call()
		if err != nil {
			t.Fatal(err.Error())
		}

		if res.MustString() != `{"arguments":[],"constructorName":"JAccount","method":"one","type":"static"}` {
			t.Fatal("response is not same with the req")
		}
	})

	if err != nil {
		t.Fatal(err.Error())
	}
}

func TestCallingStaticFuncWithArgs(t *testing.T) {
	err := withBongo(func(b *BongoKite) {
		res, err := b.Model("JAccount").Static().Func("one").CallWith("gel", "beri")
		if err != nil {
			t.Fatal(err.Error())
		}

		if res.MustString() != `{"arguments":["gel","beri"],"constructorName":"JAccount","method":"one","type":"static"}` {
			t.Fatal("response is not same with the req")
		}
	})

	if err != nil {
		t.Fatal(err.Error())
	}
}

func TestCallingInstanceFunc(t *testing.T) {
	err := withBongo(func(b *BongoKite) {
		res, err := b.Model("JAccount").Instance("123").Func("one").Call()
		if err != nil {
			t.Fatal(err.Error())
		}
		if res.MustString() != `{"arguments":[],"constructorName":"JAccount","id":"123","method":"one","type":"instance"}` {
			t.Fatal("response is not same with the req")
		}
	})

	if err != nil {
		t.Fatal(err.Error())
	}
}

func TestCallingInstanceFuncWithArgs(t *testing.T) {
	err := withBongo(func(b *BongoKite) {
		res, err := b.Model("JAccount").Instance("123").Func("one").CallWith("nil", "dil")
		if err != nil {
			t.Fatal(err.Error())
		}
		if res.MustString() != `{"arguments":["nil","dil"],"constructorName":"JAccount","id":"123","method":"one","type":"instance"}` {
			t.Fatal("response is not same with the req")
		}
	})

	if err != nil {
		t.Fatal(err.Error())
	}
}
