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
	"koding/klient/remote/req"
	"koding/klientctl/util"
	"github.com/koding/sshkey"

	"golang.org/x/crypto/ssh"
)

// SSHCommand is the cli command that lets users ssh into a remote machine.
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
	*SSHKey
}

// SSHCommandFactory is the factory method for SSHCommand.
func SSHCommandFactory(c *cli.Context) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "ssh")
		return 1
	}

	cmd, err := NewSSHCommand()
	// TODO: Refactor SSHCommand instance to require no initialization,
	// and thus avoid needing to log an error in a weird place.
	if err != nil {
		log.Errorf("Error initializing ssh: %s", err)
		fmt.Println(GenericInternalError)
		return 1
	}

	return cmd.run(c)
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
		SSHKey: &SSHKey{
			KeyPath:   path.Join(usr.HomeDir, SSHDefaultKeyDir),
			KeyName:   SSHDefaultKeyName,
			Transport: klientKite,
		},
	}, nil
}

func (s *SSHCommand) run(c *cli.Context) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "ssh")
		return 1
	}

	if !s.KeysExist() {
		util.MustConfirm("'ssh' command needs to create public/private rsa key pair. Continue? [Y|n]")
	}

	sshKey, err := s.GetSSHIp(c.Args()[0])
	if err != nil {
		log.Errorf("Error getting username and hostname combination. err:%s", err)
		fmt.Println(FailedGetSSHKey)
		return 1
	}

	if err := s.PrepareForSSH(c.Args()[0]); err != nil {
		if strings.Contains(err.Error(), "user: unknown user") {
			log.Errorf("Cannot ssh into managed machines. err:%s", err)
			fmt.Println(CannotSSHManaged)
			return 1
		}

		log.Errorf("Error getting ssh key. err:%s", err)
		fmt.Println(FailedGetSSHKey)
		return 1
	}

	cmd := exec.Command("ssh", "-i", s.PrivateKeyPath(), sshKey, "-o", "ServerAliveInterval=300", "-o", "ServerAliveCountMax=3")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		log.Errorf("Running ssh command returned an error. err:%s", err)
		return 1
	}

	return 0
}

// PrepareForSSH wrappers SSHKey.PrepareForSSH, additionally printing some basic
// information to the user.
func (s *SSHCommand) PrepareForSSH(name string) error {
	if s.KeysExist() {
		fmt.Printf("Using existing keypair at: %s \n", s.PublicKeyPath())
	} else {
		fmt.Printf("Creating new keypair at: %s \n", s.PublicKeyPath())
	}

	return s.SSHKey.PrepareForSSH(name)
}

// SSHKey implements methods for dealing with creating a KD local and remote ssh key,
// and adding it to the remote via klient's remote.sshKeysAdd
type SSHKey struct {
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

// GetSSHIp returns the username and the hostname of the remove machine to ssh.
// It assume user exists on the remove machine with the same Koding username.
func (s *SSHKey) GetSSHIp(name string) (string, error) {
	res, err := s.Tell("remote.list")
	if err != nil {
		return "", err
	}

	var infos []kiteInfo
	if err := res.Unmarshal(&infos); err != nil {
		return "", err
	}

	if info, ok := getMachineFromName(infos, name); ok {
		return fmt.Sprintf("%s@%s", info.Hostname, info.IP), nil
	}

	return "", fmt.Errorf("No machine found with specified name: `%s`", name)
}

// GetUsername returns the username of the remote machine.
// It assume user exists on the remote machine with the same Koding username.
func (s *SSHKey) GetUsername(name string) (string, error) {
	res, err := s.Tell("remote.list")
	if err != nil {
		return "", err
	}

	var infos []kiteInfo
	if err := res.Unmarshal(&infos); err != nil {
		return "", err
	}

	if info, ok := getMachineFromName(infos, name); ok {
		return info.Hostname, nil
	}

	return "", fmt.Errorf("No machine found with specified name: `%s`", name)
}

// GenerateAndSaveKey generates a new SSH key pair and saves it to local.
func (s *SSHKey) GenerateAndSaveKey() ([]byte, error) {
	var perms os.FileMode = 400

	publicKey, privateKey, err := sshkey.Generate()
	if err != nil {
		return nil, err
	}

	publicKey += fmt.Sprintf(" koding-%d", rand.Int31())

	// save ssh private key
	err = ioutil.WriteFile(s.PrivateKeyPath(), []byte(privateKey), perms)
	if err != nil {
		return nil, err
	}

	// save ssh public key
	err = ioutil.WriteFile(s.PublicKeyPath(), []byte(publicKey), perms)
	if err != nil {
		return nil, err
	}

	return []byte(publicKey), nil
}

// PublicKeyExists checks if a file exists at the PublicKeyPath
func (s *SSHKey) PublicKeyExists() bool {
	if _, err := os.Stat(s.PublicKeyPath()); os.IsNotExist(err) {
		return false
	}

	return true
}

// PrivateKeyExists checks if a file eists at the PrivateKeyPath
func (s *SSHKey) PrivateKeyExists() bool {
	if _, err := os.Stat(s.PrivateKeyPath()); os.IsNotExist(err) {
		return false
	}

	return true
}

// PublicKeyPath returns the public key path, based on the private key path
func (s *SSHKey) PublicKeyPath() string {
	return fmt.Sprintf("%s.pub", s.PrivateKeyPath())
}

// PrivateKeyPath returns the private key path, based on the SSHKey.KeyPath and
// KeyName values.
func (s *SSHKey) PrivateKeyPath() string {
	return path.Join(s.KeyPath, s.KeyName)
}

// KeysExist checks whether both keys exist.
func (s *SSHKey) KeysExist() bool {
	return s.PublicKeyExists() && s.PrivateKeyExists()
}

// PrepareForSSH checks if SSH key pair exists, if not it generates a new one
// and saves it. It adds the key pair to remote machine each time.
func (s *SSHKey) PrepareForSSH(name string) error {
	var (
		contents []byte
		err      error
	)

	if s.KeysExist() {
		if contents, err = ioutil.ReadFile(s.PublicKeyPath()); err != nil {
			return err
		}

		// check if key is valid
		if _, _, _, _, err = ssh.ParseAuthorizedKey(contents); err != nil {
			return err
		}
	} else {
		if contents, err = s.GenerateAndSaveKey(); err != nil {
			return err
		}
	}

	req := req.SSHKeyAdd{
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
