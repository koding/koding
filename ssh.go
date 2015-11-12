package main

import (
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"os/exec"
	"os/user"
	"path"
	"strings"

	"github.com/codegangsta/cli"
	"github.com/koding/klientctl/util"
	"github.com/koding/sshkey"

	"golang.org/x/crypto/ssh"
)

// SSHCommand is the cli command that lets users ssh into their remote machine.
// It manages the creating and storing of authorization keys for ease of use.
//
// On first run it generates a new SSH key pair and adds it to the requested
// machine. On subsequent requests it uses the same key pair, but adds it each
// time to user machine, since we can't assume if key exists in local, remote
// machine must also have that key, ie if user has multiple machines, but key
// was only added to one machine.
//
// Before generating a new key, it asks user to confirm or deny.
//
// SSH public keys have comment of the form: "koding-<number>", where number is
// a random integer. Klient requires a non empty comment; by adding a random
// integer to end of comment this command can be used by multiple computers.
type SSHCommand struct {
	// KeyPath is the directory that stores the ssh keys pairs. It's defaults
	// to `.ssh/` in the user's home directory.
	KeyPath string

	// KeyName is the file name of the SSH key pair. It defaults to `kd-ssh-key`.
	KeyName string

	// Transport is communication layer between this and local klient. This is
	// used to add SSH public key to `~/.ssh/authorized_keys` on the remote
	// machine.
	Transport
}

func SSHCommandFactory(c *cli.Context) int {
	cmd, err := NewSSHCommand()
	// TODO: Refactor SSHCommand instance to require no initialization,
	// and thus avoid needing to log an error in a weird place.
	if err != nil {
		fmt.Printf("Error initializing ssh: '%s'\n", err)
		return 1
	}

	return cmd.Run(c)
}

// NewSSHCommand is the required initializer for SSHCommand.
func NewSSHCommand() (*SSHCommand, error) {
	usr, err := user.Current()
	if err != nil {
		return nil, err
	}

	klientKite, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		return nil, err
	}

	if err := klientKite.Dial(); err != nil {
		return nil, err
	}

	return &SSHCommand{
		KeyPath:   path.Join(usr.HomeDir, SSHDefaultKeyDir),
		KeyName:   SSHDefaultKeyName,
		Transport: klientKite,
	}, nil
}

func (s *SSHCommand) Run(c *cli.Context) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "ssh")
		return 1
	}

	if !s.keysExist() {
		util.MustConfirm("'ssh' command needs to create public/private rsa key pair. Continue? [Y|n]")
	}

	sshKey, err := s.getSSHIp(c.Args()[0])
	if err != nil {
		fmt.Printf("Error getting ssh key: '%s'\n", err)
		return 1
	}

	if err := s.prepareForSSH(c.Args()[0]); err != nil {
		if strings.Contains(err.Error(), "user: unknown user") {
			fmt.Println("Currently unable to ssh into managed machines.")
			return 1
		}

		fmt.Printf("Error getting ssh key: '%s'\n", err)
		return 1
	}

	cmd := exec.Command("ssh", "-i", s.privateKeyPath(), sshKey)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return 1
	}

	return 0
}

// getSSHIp returns the username and the hostname of the remove machine to ssh.
// It assume user exists on the remove machine with the same Koding username.
func (s *SSHCommand) getSSHIp(name string) (string, error) {
	res, err := s.Tell("remote.list")
	if err != nil {
		return "", err
	}

	var infos []kiteInfo
	if err := res.Unmarshal(&infos); err != nil {
		return "", err
	}

	for _, info := range infos {
		if strings.HasPrefix(info.VmName, name) {
			return fmt.Sprintf("%s@%s", info.Hostname, info.Ip), nil
		}
	}

	return "", fmt.Errorf("No machine found with specified name: `%s`", name)
}

// prepareForSSH checks if SSH key pair exists, if not it generates a new one
// and saves it. It adds the key pair to remote machine each time.
func (s *SSHCommand) prepareForSSH(name string) error {
	var (
		contents []byte
		err      error
	)

	if s.keysExist() {
		fmt.Printf("Using existing keypair at: %s \n", s.publicKeyPath())

		if contents, err = ioutil.ReadFile(s.publicKeyPath()); err != nil {
			return err
		}

		// check if key is valid
		if _, _, _, _, err = ssh.ParseAuthorizedKey(contents); err != nil {
			return err
		}
	} else {
		fmt.Printf("Creating new keypair at: %s \n", s.publicKeyPath())

		if contents, err = s.generateAndSaveKey(); err != nil {
			return err
		}
	}

	req := struct {
		Name string
		Key  []byte
	}{
		Name: name,
		Key:  contents,
	}

	if _, err = s.Tell("remote.sshKeysAdd", req); err != nil {
		// ignore errors about duplicate keys since we're adding on each run
		if strings.Contains(err.Error(), "cannot add duplicate ssh key") {
			return nil
		}
	}

	return err
}

// generateAndSaveKey generates a new SSH key pair and saves it to local.
func (s *SSHCommand) generateAndSaveKey() ([]byte, error) {
	var perms os.FileMode = 400

	publicKey, privateKey, err := sshkey.Generate()
	if err != nil {
		return nil, err
	}

	publicKey += fmt.Sprintf(" koding-%d", rand.Int31())

	// save ssh private key
	err = ioutil.WriteFile(s.privateKeyPath(), []byte(privateKey), perms)
	if err != nil {
		return nil, err
	}

	// save ssh public key
	err = ioutil.WriteFile(s.publicKeyPath(), []byte(publicKey), perms)
	if err != nil {
		return nil, err
	}

	return []byte(publicKey), nil
}

func (s *SSHCommand) publicKeyExists() bool {
	if _, err := os.Stat(s.publicKeyPath()); os.IsNotExist(err) {
		return false
	}

	return true
}

func (s *SSHCommand) privateKeyExists() bool {
	if _, err := os.Stat(s.privateKeyPath()); os.IsNotExist(err) {
		return false
	}

	return true
}

func (s *SSHCommand) publicKeyPath() string {
	return fmt.Sprintf("%s.pub", s.privateKeyPath())
}

func (s *SSHCommand) privateKeyPath() string {
	return path.Join(s.KeyPath, s.KeyName)
}

func (s *SSHCommand) keysExist() bool {
	return s.publicKeyExists() && s.privateKeyExists()
}
