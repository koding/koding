package process

import (
	"bytes"
	"code.google.com/p/go.crypto/ssh"
	"crypto"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
)

type keychain struct {
	keys []interface{}
}

func KillCmd(pid int) error {
	p, err := os.FindProcess(pid)
	if err != nil {
		return err
	}

	err = p.Kill()
	if err != nil {
		return err
	}

	return nil
}

func RunCmd(cmdString string, args ...string) ([]byte, error) {
	if len(cmdString) == 0 {
		return nil, errors.New("empty string, aborting")
	}

	commands := strings.SplitAfterN(cmdString, " ", 2)

	if args == nil {
		args := make([]string, 0)
		if len(commands) >= 2 {
			args = strings.SplitAfter(commands[1], " ")
			for i, val := range args {
				args[i] = strings.TrimSpace(val)
			}
		}
	}

	command := strings.TrimSpace(commands[0])
	cmd := exec.Command(command, args...)

	// Print into the terminal
	// cmd.Stdout = os.Stdout
	// cmd.Stderr = os.Stderr

	// Open in background
	// cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}

	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}

	return out, nil
}

func StopPid(pid int) error {
	process, err := os.FindProcess(pid)
	if err != nil {
		log.Printf("failed to find process: %s\n", err)
	}

	err = process.Signal(syscall.SIGSTOP)
	if err != nil {
		return err
	}
	return nil
}

func CheckPid(pid int) error {
	process, err := os.FindProcess(pid)
	if err != nil {
		log.Printf("failed to find process: %s\n", err)
	}

	err = process.Signal(syscall.Signal(0))
	if err != nil {
		return errors.New("pid terminated or not owned by me")
	}
	return nil // pid exists
}

func SignalWatcher() {
	// For future reference, if we can do stuff for ctrl+c
	signals := make(chan os.Signal, 1)
	signal.Notify(signals)
	for {
		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM:
			log.Fatalf("received '%s' signal; exiting", signal)
			os.Exit(1)
		default:
			log.Printf("received '%s' signal; unhandled", signal)
		}
	}
}

func (k *keychain) Key(i int) (interface{}, error) {
	if i < 0 || i >= len(k.keys) {
		return nil, nil
	}
	switch key := k.keys[i].(type) {
	case *rsa.PrivateKey:
		return &key.PublicKey, nil
	}
	return nil, errors.New("ssh: unknown key type")
}

func (k *keychain) Sign(i int, rand io.Reader, data []byte) (sig []byte, err error) {
	hashFunc := crypto.SHA1
	h := hashFunc.New()
	h.Write(data)
	digest := h.Sum(nil)
	switch key := k.keys[i].(type) {
	case *rsa.PrivateKey:
		return rsa.SignPKCS1v15(rand, key, hashFunc, digest)
	}
	return nil, errors.New("ssh: unknown key type")
}

func (k *keychain) LoadPEM(file string) error {
	buf, err := ioutil.ReadFile(file)
	if err != nil {
		return err
	}
	block, _ := pem.Decode(buf)
	if block == nil {
		return errors.New("ssh: no key found")
	}
	r, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return err
	}
	k.keys = append(k.keys, r)
	return nil
}

func RunSshCmd(cmdString string) string {
	key := new(keychain)
	err := key.LoadPEM("/Users/fatih/.ssh/koding_rsa")
	if err != nil {
		log.Println(err)

	}

	config := &ssh.ClientConfig{
		User: "ubuntu",
		Auth: []ssh.ClientAuth{
			ssh.ClientAuthKeyring(key),
		},
	}

	client, err := ssh.Dial("tcp", "ktl.koding.com:22", config)
	if err != nil {
		log.Println("Failed to dial", err)
	}

	session, err := client.NewSession()
	if err != nil {
		log.Println("Failed to create session", err)
	}
	defer session.Close()

	var b bytes.Buffer
	session.Stdout = &b
	if err := session.Run("/bin/hostname"); err != nil {
		log.Println("Failed to run: ", err)
	}

	return b.String()
}
