package ssh

import (
	"errors"
	"fmt"
	"io/ioutil"
	"math/rand"
	"os"
	"os/exec"
	"os/user"
	"path"
	"strings"

	"koding/klient/remote/req"
	"koding/klientctl/config"
	"koding/klientctl/klient"
	"koding/klientctl/klientctlerrors"
	"koding/klientctl/list"
	"koding/klientctl/util"

	"github.com/koding/kite/dnode"

	"github.com/koding/sshkey"

	"golang.org/x/crypto/ssh"
)

var (
	ErrManagedMachineNotSupported = errors.New("Cannot ssh into managed machines.")

	ErrFailedToGetSSHKey = errors.New("Failed to get ssh key.")

	ErrMachineNotValidYet = errors.New("Machine not valid yet")
)

// SSHCommand is the command that lets users ssh into a remote machine.  It
// manages the creating and storing of authorization keys for ease of use.
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

	// Ask is flag for user interaction, ie should we ask user to generate new
	// SSH key if it doesn't exist.
	Ask bool
}

// NewSSHCommand is the required initializer for SSHCommand.
func NewSSHCommand(ask bool) (*SSHCommand, error) {
	usr, err := user.Current()
	if err != nil {
		return nil, err
	}

	klientKite, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		return nil, err
	}

	if err := klientKite.Dial(); err != nil {
		return nil, err
	}

	return &SSHCommand{
		Ask: ask,
		SSHKey: &SSHKey{
			KeyPath: path.Join(usr.HomeDir, config.SSHDefaultKeyDir),
			KeyName: config.SSHDefaultKeyName,
			Klient:  klient.NewKlient(klientKite),
		},
	}, nil
}

func (s *SSHCommand) Run(machine string) error {
	if !s.KeysExist() && s.Ask {
		util.MustConfirm("'ssh' command needs to create public/private rsa key pair. Continue? [Y|n]")
	}

	sshKey, err := s.GetSSHIp(machine)
	if err != nil {
		return err
	}

	if err := s.PrepareForSSH(machine); err != nil {
		if strings.Contains(err.Error(), "user: unknown user") {
			return ErrManagedMachineNotSupported
		}

		// TODO: We're unable to log the meaningful error returned from klient, so we're
		// leaking possibly meaningful data here. This will be resolved once SSH gets
		// updated to the new (final) format. Fix this.
		if klientctlerrors.IsMachineNotValidYetErr(err) {
			return ErrMachineNotValidYet
		}

		return ErrFailedToGetSSHKey
	}

	cmd := exec.Command("ssh", "-i", s.PrivateKeyPath(), sshKey, "-o", "ServerAliveInterval=300", "-o", "ServerAliveCountMax=3")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
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

	// Klient is communication layer between this and local klient. This is
	// used to add SSH public key to `~/.ssh/authorized_keys` on the remote
	// machine.
	Klient interface {
		RemoteList() (list.KiteInfos, error)
		Tell(string, ...interface{}) (*dnode.Partial, error)
	}
}

// GetSSHIp returns the username and the hostname of the remove machine to ssh.
// It assume user exists on the remove machine with the same Koding username.
func (s *SSHKey) GetSSHIp(name string) (string, error) {
	infos, err := s.Klient.RemoteList()
	if err != nil {
		return "", err
	}

	if info, ok := infos.FindFromName(name); ok {
		return fmt.Sprintf("%s@%s", info.Hostname, info.IP), nil
	}

	return "", fmt.Errorf("No machine found with specified name: `%s`", name)
}

// GetUsername returns the username of the remote machine.
// It assume user exists on the remote machine with the same Koding username.
func (s *SSHKey) GetUsername(name string) (string, error) {
	infos, err := s.Klient.RemoteList()
	if err != nil {
		return "", err
	}

	if info, ok := infos.FindFromName(name); ok {
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

	if _, err = s.Klient.Tell("remote.sshKeysAdd", req); err != nil {
		// ignore errors about duplicate keys since we're adding on each run
		if strings.Contains(err.Error(), "cannot add duplicate ssh key") {
			return nil
		}
	}

	return err
}
