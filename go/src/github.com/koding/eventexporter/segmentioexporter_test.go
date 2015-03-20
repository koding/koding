package eventexporter

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

type segmentRequest struct {
	Batch []struct {
		Event      string                 `json:"event"`
		Properties map[string]interface{} `json:"properties"`
		UserID     string                 `json:"userId"`
	} `json:"batch"`
}

func TestSegmentIOExporter(t *testing.T) {
	messageArrived := make(chan *segmentRequest)

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		buf := bytes.NewBuffer(nil)
		io.Copy(buf, r.Body)

		var req segmentRequest
		err := json.Unmarshal(buf.Bytes(), &req)
		if err != nil {
			panic(err)
		}

		messageArrived <- &req
	})

	server := httptest.NewServer(mux)
	url, _ := url.Parse(server.URL)

	defer server.Close()

	Convey("When using SegementIOExporter", t, func() {
		props := map[string]interface{}{"key": "a"}
		user := &User{Username: "indianajones", Email: "senthil@koding.com"}
		event := &Event{Name: "test", Properties: props, User: user}

		sender := NewSegementIOExporter("", 1)
		sender.Client.Endpoint = url.String()

		err := sender.Send(event)
		So(err, ShouldBeNil)

		Convey("Then it should send", func() {
			var req *segmentRequest
			var timeout = time.NewTimer(time.Second * 2).C

			select {
			case req = <-messageArrived:
				So(len(req.Batch), ShouldEqual, 1)
			case <-timeout:
				t.Fatal("no response from request to segmentio")
			}

			p := req.Batch[0]
			So(p.UserID, ShouldEqual, "indianajones")
			So(p.Event, ShouldEqual, "test")
			So(p.Properties, ShouldNotBeNil)

			key, ok := p.Properties["key"]
			So(ok, ShouldBeTrue)
			So(key.(string), ShouldEqual, "a")
		})
	})
}
