package sender

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

type segmentRequest struct {
	Batch []struct {
		Event      string                 `json:"event"`
		Properties map[string]interface{} `json:"properties"`
		UserID     string                 `json:"userId"`
	} `json:"batch"`
}

func TestSegmentIOSender(t *testing.T) {
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

	Convey("", t, func() {
		props := map[string]interface{}{"key": "a"}
		user := &User{Username: "indianajones"}
		event := &Event{Name: "test", Properties: props, User: user}

		sender := NewSegementIOSender(url.String(), "")
		sender.Client.Size = 1

		err := sender.Send(event)
		So(err, ShouldBeNil)

		req := <-messageArrived
		So(len(req.Batch), ShouldEqual, 1)

		p := req.Batch[0]
		So(p.UserID, ShouldEqual, "indianajones")
		So(p.Event, ShouldEqual, "test")
		So(p.Properties, ShouldNotBeNil)

		key, ok := p.Properties["key"]
		So(ok, ShouldBeTrue)
		So(key.(string), ShouldEqual, "a")
	})
}
