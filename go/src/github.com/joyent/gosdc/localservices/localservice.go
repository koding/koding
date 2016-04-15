//
// gosdc - Go library to interact with the Joyent CloudAPI
//
// Double testing service
//
// Copyright (c) Joyent Inc.
//

package localservices

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"io"

	"github.com/joyent/gosdc/localservices/hook"
	"github.com/julienschmidt/httprouter"
)

// An HttpService provides the HTTP API for a service double.
type HttpService interface {
	SetupHTTP(mux *httprouter.Router)
}

// A ServiceInstance is an Joyent Cloud service.
type ServiceInstance struct {
	hook.TestService
	Scheme      string
	Hostname    string
	UserAccount string
}

// NewUUID generates a random UUID according to RFC 4122
func NewUUID() (string, error) {
	uuid := make([]byte, 16)
	n, err := io.ReadFull(rand.Reader, uuid)
	if n != len(uuid) || err != nil {
		return "", err
	}
	uuid[8] = uuid[8]&^0xc0 | 0x80
	uuid[6] = uuid[6]&^0xf0 | 0x40
	return fmt.Sprintf("%x-%x-%x-%x-%x", uuid[0:4], uuid[4:6], uuid[6:8], uuid[8:10], uuid[10:]), nil
}

// NewMAC generates a new fake MAC address
func NewMAC() (string, error) {
	mac := make([]byte, 6)
	n, err := io.ReadFull(rand.Reader, mac)
	if n != len(mac) || err != nil {
		return "", err
	}
	e := hex.EncodeToString(mac)

	return fmt.Sprintf("%s:%s:%s:%s:%s:%s", e[0:2], e[2:4], e[4:6], e[6:8], e[8:10], e[10:12]), nil
}
