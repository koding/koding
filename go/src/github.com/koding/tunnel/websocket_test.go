package tunnel_test

import (
	"fmt"
	"net/http"
	"reflect"
	"testing"

	"github.com/koding/tunnel/tunneltest"
)

func testWebsocket(name string, n int, t *testing.T, tt *tunneltest.TunnelTest) {
	conn, err := websocketDial(tt, "http")
	if err != nil {
		t.Fatalf("Dial()=%s", err)
	}
	defer conn.Close()

	for i := 0; i < n; i++ {
		want := &EchoMessage{
			Value: fmt.Sprintf("message #%d", i),
			Close: i == (n - 1),
		}

		err := conn.WriteJSON(want)
		if err != nil {
			t.Errorf("(test %s) %d: failed sending %q: %s", name, i, want, err)
			continue
		}

		got := &EchoMessage{}

		err = conn.ReadJSON(got)
		if err != nil {
			t.Errorf("(test %s) %d: failed reading: %s", name, i, err)
			continue
		}

		if !reflect.DeepEqual(got, want) {
			t.Errorf("(test %s) %d: got %+v, want %+v", name, i, got, want)
		}
	}
}

func testHandler(t *testing.T, fn func(w http.ResponseWriter, r *http.Request) error) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := fn(w, r); err != nil {
			t.Errorf("handler func error: %s", err)
		}
	}
}

func TestWebsocket(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(testHandler(t, handlerEchoWS(nil))))
	if err != nil {
		t.Fatal(err)
	}

	testWebsocket("handlerEchoWS", 100, t, tt)
}

func TestLatencyWebsocket(t *testing.T) {
	tt, err := tunneltest.Serve(singleHTTP(testHandler(t, handlerEchoWS(sleep))))
	if err != nil {
		t.Fatal(err)
	}

	testWebsocket("handlerLatencyEchoWS", 20, t, tt)
}
