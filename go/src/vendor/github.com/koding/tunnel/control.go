package tunnel

import (
	"encoding/json"
	"errors"
	"net"
	"sync"
)

var errControlClosed = errors.New("control connection is closed")

type control struct {
	// enc and dec are responsible for encoding and decoding json values forth
	// and back
	enc *json.Encoder
	dec *json.Decoder

	// underlying connection responsible for encoder and decoder
	nc net.Conn

	// identifier associated with this control
	identifier string

	mu     sync.Mutex // guards the following
	closed bool       // if Close() and quits
}

func newControl(nc net.Conn) *control {
	c := &control{
		enc: json.NewEncoder(nc),
		dec: json.NewDecoder(nc),
		nc:  nc,
	}

	return c
}

func (c *control) send(v interface{}) error {
	if c.enc == nil {
		return errors.New("encoder is not initialized")
	}

	c.mu.Lock()
	if c.closed {
		c.mu.Unlock()
		return errControlClosed
	}
	c.mu.Unlock()

	return c.enc.Encode(v)
}

func (c *control) recv(v interface{}) error {
	if c.dec == nil {
		return errors.New("decoder is not initialized")
	}

	c.mu.Lock()
	if c.closed {
		c.mu.Unlock()
		return errControlClosed
	}
	c.mu.Unlock()

	return c.dec.Decode(v)
}

func (c *control) Close() error {
	if c.nc == nil {
		return nil
	}

	c.mu.Lock()
	c.closed = true
	c.mu.Unlock()

	return c.nc.Close()
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
	control.identifier = identifier

	c.Lock()
	c.controls[identifier] = control
	c.Unlock()
}

func (c *controls) deleteControl(identifier string) {
	c.Lock()
	delete(c.controls, identifier)
	c.Unlock()
}
