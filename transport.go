package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os/user"
	"strings"
	"time"

	"github.com/koding/kite"
)

// Transport defines communication between this package and user VM.
type Transport interface {
	Trip(string, interface{}, interface{}) error
}

//----------------------------------------------------------
// KlientTransport
//----------------------------------------------------------

const (
	kiteName    = "fuseproto"
	kiteVersion = "0.0.1"
	kiteTimeout = 10 * time.Second
)

// KlientTransport is a Transport using Klient on user VM.
type KlientTransport struct {
	client *kite.Client
}

// NewKlientTransport initializes KlientTransport with Klient connection.
func NewKlientTransport(klientIP string) (*KlientTransport, error) {
	k := kite.New(kiteName, kiteVersion)

	kiteClient := k.NewClient(fmt.Sprintf("http://%s:56789/kite", klientIP))

	// os/user has issues with cross compiling, so we may want to use
	// the following library instead:
	//
	// 	https://github.com/mitchellh/go-homedir
	usr, err := user.Current()
	if err != nil {
		return nil, err
	}

	data, err := ioutil.ReadFile(fmt.Sprintf(
		"%s/.fuseklient/keys/%s.kite.key", usr.HomeDir, klientIP,
	))
	if err != nil {
		return nil, err
	}

	kiteClient.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  strings.TrimSpace(string(data)),
	}
	kiteClient.Reconnect = true

	if err := kiteClient.DialTimeout(kiteTimeout); err != nil {
		return nil, err
	}

	return &KlientTransport{client: kiteClient}, nil
}

// Trip is a generic method for communication. It accepts `req` to pass args
// to Klient and `res` to store unmarshalled response from Klient.
func (k *KlientTransport) Trip(methodName string, req interface{}, res interface{}) error {
	raw, err := k.client.Tell(methodName, req)
	if err != nil {
		return err
	}

	return raw.Unmarshal(&res)
}

//----------------------------------------------------------
// Responses
//----------------------------------------------------------

type fsReadDirectoryRes struct {
	Files []fsGetInfoRes `json:"files"`
}

type fsGetInfoRes struct {
	Exists   bool   `json:"exists"`
	FullPath string `json:"fullPath"`
	IsBroken bool   `json:"isBroken"`
	IsDir    bool   `json:"isDir"`
	Mode     int    `json:"mode"`
	Name     string `json:"name"`
	Readable bool   `json:"readable"`
	Size     int    `json:"size"`
	Time     string `json:"time"`
	Writable bool   `json:"writable"`
}

type fsReadFileRes struct {
	Content []byte
}

func (f *fsReadFileRes) UnmarshalJSON(b []byte) error {
	var m map[string]string
	if err := json.Unmarshal(b, &m); err != nil {
		return err
	}

	data, err := base64.StdEncoding.DecodeString(m["content"])
	if err != nil {
		return err
	}

	f.Content = data

	return nil
}
