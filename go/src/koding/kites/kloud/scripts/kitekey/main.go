package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"

	"koding/kites/kloud/keycreator"

	"github.com/koding/kite/kitekey"
	"github.com/satori/go.uuid"
)

var (
	username   = flag.String("username", "", "kite.key username")
	kontrolURL = flag.String("kontrolurl", "", "kite.key kontrol URL")
	pem        = flag.String("pem", "", "private key to encrypt/decrypt kite.key")
	pub        = flag.String("pub", "", "kite.key kontrol key")
	id         = flag.String("id", "", "use fixed kite ID instead of generated one")
	file       = flag.String("file", "", "kite.key path")
)

func die(v ...interface{}) {
	fmt.Fprintln(os.Stderr, v...)
	os.Exit(1)
}

func main() {
	flag.Parse()

	var err error

	if *file != "" && *pem != "" && *pub != "" {
		err = create()
	} else {
		err = show()
	}

	if err != nil {
		die(err)
	}
}

func show() error {
	tok, err := kitekey.ParseFile(*file)
	if err != nil {
		return fmt.Errorf("reading %q failed: %s", *file, err)
	}

	return json.NewEncoder(os.Stdout).Encode(tok.Claims)
}

func create() error {
	pemBytes, err := ioutil.ReadFile(*pem)
	if err != nil {
		return fmt.Errorf("reading -pem key failed: %s", err)
	}

	pubBytes, err := ioutil.ReadFile(*pub)
	if err != nil {
		return fmt.Errorf("reading -pub key failed: %s", err)
	}

	if *id == "" {
		*id = uuid.NewV4().String()
	}

	k := &keycreator.Key{
		KontrolURL:        *kontrolURL,
		KontrolPrivateKey: string(bytes.TrimSpace(pemBytes)),
		KontrolPublicKey:  string(bytes.TrimSpace(pubBytes)),
	}

	kiteKey, err := k.Create(*username, *id)
	if err != nil {
		return fmt.Errorf("signing failed: %s", err)
	}

	if *file == "" {
		fmt.Println(kiteKey)
		return nil
	}

	return ioutil.WriteFile(*file, bytes.TrimSpace([]byte(kiteKey)), 0644)
}
