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

func GenerateKeys() (pubKey string, privKey string, err error) {

	// genereate key pair
	privateKey, err := rsa.GenerateKey(rand.Reader, 2014)
	if err != nil {
		return "", "", err
	}

	/// convert to private key
	privateKeyDer := x509.MarshalPKCS1PrivateKey(privateKey)
	privateKeyBlock := pem.Block{
		Type:    "RSA PRIVATE KEY",
		Headers: nil,
		Bytes:   privateKeyDer,
	}
	privateKeyPem := string(pem.EncodeToMemory(&privateKeyBlock))

	// convert to public key
	publicKey := privateKey.PublicKey
	publicKeyDer, err := x509.MarshalPKIXPublicKey(&publicKey)
	if err != nil {
		return "", "", err
	}
	publicKeyBlock := pem.Block{
		Type:    "PUBLIC KEY",
		Headers: nil,
		Bytes:   publicKeyDer,
	}
	publicKeyPem := string(pem.EncodeToMemory(&publicKeyBlock))

	// fmt.Println(privateKeyPem)
	fmt.Println(publicKeyPem)

	privKey = privateKeyPem

	////
	pub, err := ssh.NewPublicKey(&publicKey)
	if err != nil {
		return "", "", err
	}

	pubKey = fmt.Sprintf("ssh-rsa %v", base64.StdEncoding.EncodeToString(pub.Marshal()))

	return pubKey, privKey, nil
}
