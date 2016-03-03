package simplehttp

import (
	"bytes"
	"io/ioutil"
	"testing"
)

func TestFormDataPayloadPost(t *testing.T) {
	payload := NewFormDataPayload()
	payload.AddValue("key", "value")

	buf := &bytes.Buffer{}
	buf.Write([]byte("testing testing testing"))

	rc := ioutil.NopCloser(buf)
	payload.AddReadCloser("foo", "bar", rc)

	request := NewHTTPRequest(dummyurl)
	request.MakePostRequest(payload)
}

func TestUrlEncodedPayloadPost(t *testing.T) {
	payload := NewUrlEncodedPayload()
	payload.AddValue("key", "value")
	request := NewHTTPRequest(dummyurl)
	request.MakePostRequest(payload)
}
