package digitalocean

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"log"
	"time"

	"code.google.com/p/go.crypto/ssh"
)

const (
	sshConnectRetryInterval = 4 * time.Second
	sshConnectMaxWait       = 1 * time.Minute
)

type sshClient struct {
	*ssh.Client
}

func (s *sshClient) StartCommand(command string) error {
	session, err := s.NewSession()
	if err != nil {
		return err
	}
	defer session.Close()

	// TODO: add STDIN for enalbing uploading of files

	stdoutBuffer, stderrBuffer := new(bytes.Buffer), new(bytes.Buffer)
	session.Stdout, session.Stderr = stdoutBuffer, stderrBuffer

	fmt.Println("running ls on remote machine")
	if err := session.Start(command); err != nil {
		fmt.Println("run session err:", err)
	}

	// Wait for the SCP connection to close, meaning it has consumed all
	// our data and has completed. Or has errored.
	log.Println("Waiting for SSH session to complete.")
	err = session.Wait()
	if err != nil {
		if exitErr, ok := err.(*ssh.ExitError); ok {
			// Otherwise, we have an ExitErorr, meaning we can just read
			// the exit status
			log.Printf("non-zero exit status: %d", exitErr.ExitStatus())

			// If we exited with status 127, it means SCP isn't available.
			// Return a more descriptive error for that.
			if exitErr.ExitStatus() == 127 {
				return errors.New(
					"SCP failed to start. This usually means that SCP is not\n" +
						"properly installed on the remote system.")
			}
		}

		return err
	}

	fmt.Printf("Ssh completed stdout: %s, stderr: %s\n",
		stdoutBuffer.String(), stderrBuffer.String())

	return nil

}

// connectSSH tries to connect to the given IP and returns a new client.
func connectSSH(ip string, config *ssh.ClientConfig) (*sshClient, error) {
	for {
		select {
		case <-time.Tick(sshConnectRetryInterval):
			client, err := ssh.Dial("tcp", ip, config)
			if err != nil {
				fmt.Println("Failed to dial, will retry: " + err.Error())
				continue
			}
			return &sshClient{Client: client}, nil
		case <-time.After(sshConnectMaxWait):
			return nil, errors.New("cannot connect with ssh")
		}
	}
}

// sshConfig returns a new clientConfig based on the given privateKey
func sshConfig(privateKey string) (*ssh.ClientConfig, error) {
	signer, err := ssh.ParsePrivateKey([]byte(privateKey))
	if err != nil {
		return nil, fmt.Errorf("Error setting up SSH config: %s", err)
	}

	return &ssh.ClientConfig{
		User: "root",
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
	}, nil
}

// temporaryKey creates a new temporary public and private key
func temporaryKey() (string, string, error) {
	priv, err := rsa.GenerateKey(rand.Reader, 2014)
	if err != nil {
		return "", "", err
	}

	// ASN.1 DER encoded form
	priv_der := x509.MarshalPKCS1PrivateKey(priv)
	priv_blk := pem.Block{
		Type:    "RSA PRIVATE KEY",
		Headers: nil,
		Bytes:   priv_der,
	}

	privateKey := string(pem.EncodeToMemory(&priv_blk))

	// Marshal the public key into SSH compatible format
	// TODO properly handle the public key error
	pub, _ := ssh.NewPublicKey(&priv.PublicKey)
	pub_sshformat := string(ssh.MarshalAuthorizedKey(pub))

	return privateKey, pub_sshformat, nil
}
