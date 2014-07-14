package bongoscheme

import "testing"

func TestCallingStaticFunc(t *testing.T) {
	bongo, err := New(&Config{Version: "0.0.1", ClientURL: "http://localhost:3636/kite"})
	if err != nil {
		t.Fatal(err.Error())
	}
	defer bongo.Close()

	res, err := bongo.Model("JAccount").Static().Func("one").Call()
	if err != nil {
		t.Fatal(err.Error())
	}
	if res.MustString() != `{"arguments":[],"constructorName":"JAccount","method":"one","type":"static"}` {
		t.Fatal("response is not same with the req")
	}
}

func TestCallingStaticFuncWithArgs(t *testing.T) {
	bongo, err := New(&Config{Version: "0.0.1", ClientURL: "http://localhost:3636/kite"})
	if err != nil {
		t.Fatal(err.Error())
	}
	defer bongo.Close()

	res, err := bongo.Model("JAccount").Static().Func("one").CallWith("gel", "beri")
	if err != nil {
		t.Fatal(err.Error())
	}
	if res.MustString() != `{"arguments":["gel","beri"],"constructorName":"JAccount","method":"one","type":"static"}` {
		t.Fatal("response is not same with the req")
	}
}

func TestCallingInstanceFunc(t *testing.T) {
	bongo, err := New(&Config{Version: "0.0.1", ClientURL: "http://localhost:3636/kite"})
	if err != nil {
		t.Fatal(err.Error())
	}
	defer bongo.Close()

	res, err := bongo.Model("JAccount").Instance("123").Func("one").Call()
	if err != nil {
		t.Fatal(err.Error())
	}
	if res.MustString() != `{"arguments":[],"constructorName":"JAccount","id":"123","method":"one","type":"instance"}` {
		t.Fatal("response is not same with the req")
	}
}

func TestCallingInstanceFuncWithArgs(t *testing.T) {
	bongo, err := New(&Config{Version: "0.0.1", ClientURL: "http://localhost:3636/kite"})
	if err != nil {
		t.Fatal(err.Error())
	}
	defer bongo.Close()

	res, err := bongo.Model("JAccount").Instance("123").Func("one").CallWith("nil", "dil")
	if err != nil {
		t.Fatal(err.Error())
	}
	if res.MustString() != `{"arguments":["nil","dil"],"constructorName":"JAccount","id":"123","method":"one","type":"instance"}` {
		t.Fatal("response is not same with the req")
	}
}
