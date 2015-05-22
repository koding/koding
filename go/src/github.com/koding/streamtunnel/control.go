package streamtunnel

import (
	"encoding/json"
	"errors"
	"net"
	"sync"
)

type control struct {
	enc *json.Encoder
	dec *json.Decoder
}

func newControl(nc net.Conn) *control {
	c := &control{
		enc: json.NewEncoder(nc),
		dec: json.NewDecoder(nc),
	}

	return c
}

func (c *control) send(v interface{}) error {
	if c.enc == nil {
		return errors.New("encoder is not initialized")
	}

	return c.enc.Encode(v)
}

func (c *control) recv(v interface{}) error {
	if c.dec == nil {
		return errors.New("decoder is not initialized")
	}

	return c.dec.Decode(v)
}

type controls struct {
	sync.Mutex
	controls map[string]*control
}

func newControls() *controls {
	return &controls{
		controls: make(map[string]*control),
	}
}

func (c *controls) getControl(identifier string) (*control, bool) {
	c.Lock()
	control, ok := c.controls[identifier]
	c.Unlock()
	return control, ok
}

func (c *controls) addControl(identifier string, control *control) {
	c.Lock()
	c.controls[identifier] = control
	c.Unlock()
}

func (c *controls) deleteControl(identifier string) {
	c.Lock()
	delete(c.controls, identifier)
	c.Unlock()
}
