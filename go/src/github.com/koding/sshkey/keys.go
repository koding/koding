// Package sshkey provides public and private key pair for ssh usage
package sshkey

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"fmt"

	"golang.org/x/crypto/ssh"
)

const (
	// This is a default value for private key block
	privateKeyType = "RSA PRIVATE KEY"
	// while generating ssh key,
	// 2048 bit size is the default size.
	// as optional it can be 1024 or 4096 etc..
	bitSize = 2048
)

// Generate creates public and private key pairs for using as ssh keys uses
// RSA for generating keys
func Generate() (pubKey string, privKey string, err error) {
	// genereate key pair
	privateKey, err := rsa.GenerateKey(rand.Reader, bitSize)
	if err != nil {
		return "", "", err
	}

	/// convert to private key block
	privateKeyBlock := pem.Block{
		Type:    privateKeyType,
		Headers: nil,
		Bytes:   x509.MarshalPKCS1PrivateKey(privateKey),
	}

	// convert to public key
	pub, err := ssh.NewPublicKey(&privateKey.PublicKey)
	if err != nil {
		return "", "", err
	}

	// standart github ssh preferences
	pubKey = fmt.Sprintf("ssh-rsa %v", base64.StdEncoding.EncodeToString(pub.Marshal()))
	privKey = string(pem.EncodeToMemory(&privateKeyBlock))

	return pubKey, privKey, nil
}
