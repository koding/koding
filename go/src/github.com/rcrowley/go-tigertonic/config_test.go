package tigertonic

import "testing"

func TestConfigure(t *testing.T) {
	c := &testConfig{}
	if err := Configure("", &c); nil != err {
		t.Fatal(err)
	}
	if "" != c.Foo || 0 != c.Bar {
		t.Fatal(c)
	}
	if err := Configure("config_test", &c); nil == err {
		t.Fatal(err)
	}
	if "" != c.Foo || 0 != c.Bar {
		t.Fatal(c)
	}
	if err := Configure("config_test.yaml", &c); nil == err {
		t.Fatal(err)
	}
	if "" != c.Foo || 0 != c.Bar {
		t.Fatal(c)
	}
}

func TestConfigureJSON(t *testing.T) {
	c := &testConfig{}
	if err := Configure("config_test.json", &c); nil != err {
		t.Fatal(err)
	}
	if "foo" != c.Foo || 47 != c.Bar {
		t.Fatal(c)
	}
}

type testConfig struct {
	Foo string
	Bar int
}
