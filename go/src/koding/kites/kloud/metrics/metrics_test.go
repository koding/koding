package metrics

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/koding/kite"
)

func TestPublishEndpoint(t *testing.T) {
	tsrv := kite.New("test-server", "0.0.0")
	tsrv.Config.DisableAuthentication = true
	if err := tsrv.Config.ReadEnvironmentVariables(); err != nil {
		t.Fatal(err)
	}

	server, conn, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}

	// ignore messages
	blackHole := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	defer blackHole.Close()

	pub := NewPublisherWithConn(conn, blackHole.URL)

	tsrv.HandleFunc(pub.Pattern(), pub.Publish)

	ts := httptest.NewServer(tsrv)
	tcli := kite.New("test-client", "0.0.0")
	if err = tcli.Config.ReadEnvironmentVariables(); err != nil {
		t.Fatal(err)
	}

	c := tcli.NewClient(fmt.Sprintf("%s/kite", ts.URL))
	if err = c.Dial(); err != nil {
		t.Fatalf("dialing test-server kite error: %s", err)
	}

	gzm := newRandomPublishReq(20)

	_, err = c.Tell(pub.Pattern(), gzm)
	if err != nil {
		t.Fatalf("Tell()=%s", err)
	}

	if err = conn.Close(); err != nil {
		t.Fatalf("conn.Close()=%s", err)
	}

	d, err := ioutil.ReadAll(server)
	if err != nil {
		t.Fatalf("ioutil.ReadAll(r)=%s", err)
	}

	for _, data := range gzm.Data {
		d = bytes.Replace(d, data, nil, -1)
	}

	if len(d) > 0 {
		t.Fatalf("len(d) should be > 0, got %d", len(d))
	}
}
