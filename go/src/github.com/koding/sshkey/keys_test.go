package sshkey

import (
	"strings"
	"testing"
)

func TestGenerateKey(t *testing.T) {
	pub, priv, err := Generate()
	if pub == "" {
		t.Fatal("public key is not valid")
	}

	if priv == "" {
		t.Fatal("private key is not valid")
	}

	if !strings.Contains(priv, privateKeyType) {
		t.Fatal("priv key doesnt have %s", privateKeyType)
	}

	if err != nil {
		t.Fatal("err while creating key pairs %s", err.Error())
	}
}
