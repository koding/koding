// The core logic for the `kd ssh` command.
//
// TODO(ppknap) this logic is deprecated. Remove it once we switch to new
// machine commands entirely.
package ssh

import (
	"errors"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net"
	"os"
	"os/exec"
	"os/user"
	"path"
	"path/filepath"
	"strings"

	"koding/kites/tunnelproxy/discover"
	"koding/klient/remote/req"
	"koding/klientctl/config"
	"koding/klientctl/klient"
	"koding/klientctl/klientctlerrors"
	"koding/klientctl/list"
	"koding/klientctl/shortcut"
	"koding/klientctl/util"

	"github.com/koding/kite/dnode"
	"github.com/koding/logging"

	"github.com/koding/sshkey"

	"golang.org/x/crypto/ssh"
)

var (
	ErrCannotFindUser = errors.New("Cannot find username on remote machine.")

	ErrFailedToGetSSHKey = errors.New("Failed to get ssh key.")

	ErrMachineNotValidYet = errors.New("Machine not valid yet.")

	ErrRemoteDialingFailed = errors.New("Dialing remote failed.")

	// Dialing the local klient failed, ie klient is not running or accepting
	// connections.
	ErrLocalDialingFailed = errors.New("Local dialing failed.")

	// ErrMachineNotFound is when the requested machine is not found.
	ErrMachineNotFound = errors.New("Machine not found.")
)

type SSHCommandOpts struct {
	Ask bool

	// The Remote SSH Username to connect with.
	RemoteUsername string

	// Whether to log with debug, and pass debug to Klient.
	Debug bool
}

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

	Log   logging.Logger
	Debug bool

	// Ask is flag for user interaction, ie should we ask user to generate new
	// SSH key if it doesn't exist.
	Ask bool

	// Klient is communication layer between this and local klient. This is
	// used to add SSH public key to `~/.ssh/authorized_keys` on the remote
	// machine.
	Klient interface {
		RemoteList() (list.KiteInfos, error)
	}
}

// NewSSHCommand is the required initializer for SSHCommand.
func NewSSHCommand(log logging.Logger, opts SSHCommandOpts) (*SSHCommand, error) {
	usr, err := user.Current()
	if err != nil {
		return nil, err
	}

	klientKite, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		return nil, err
	}

	if err := klientKite.Dial(); err != nil {
		log.New("NewSSHCommand").Error("Dialing local klient failed. err:%s", err)
		return nil, ErrLocalDialingFailed
	}

	k := klient.NewKlient(klientKite)

	return &SSHCommand{
		Klient: k,
		Log:    log.New("SSHCommand"),
		Ask:    opts.Ask,
		Debug:  opts.Debug,
		SSHKey: &SSHKey{
			Log:            log.New("SSHKey"),
			Debug:          opts.Debug,
			RemoteUsername: opts.RemoteUsername,
			KeyPath:        path.Join(usr.HomeDir, config.SSHDefaultKeyDir),
			KeyName:        config.SSHDefaultKeyName,
			Klient:         k,
		},
	}, nil
}

func (s *SSHCommand) Run(machine string) error {
	if !s.KeysExist() && s.Ask {
		util.MustConfirm("'ssh' command needs to create public/private rsa key pair. Continue? [Y|n]")
	}

	machine, err := shortcut.NewMachineShortcut(s.Klient).GetNameFromShortcut(machine)
	if err != nil {
		return err
	}

	userhost, port, err := s.GetSSHAddr(machine)
	if err != nil {
		return err
	}

	if err := s.PrepareForSSH(machine); err != nil {
		s.Log.Debug("PrepareForSSH returned err: %s", err)

		if strings.Contains(err.Error(), "user: unknown user") {
			return ErrCannotFindUser
		}

		// TODO: We're unable to log the meaningful error returned from klient, so we're
		// leaking possibly meaningful data here. This will be resolved once SSH gets
		// updated to the new (final) format. Fix this.
		if klientctlerrors.IsMachineNotValidYetErr(err) {
			return ErrMachineNotValidYet
		}

		if klientctlerrors.IsDialFailedErr(err) {
			return ErrRemoteDialingFailed
		}

		return ErrFailedToGetSSHKey
	}

	args := []string{
		"-i", s.PrivateKeyPath(),
		"-o", "ServerAliveInterval=300",
		"-o", "ServerAliveCountMax=3",
		"-o", "ConnectTimeout=7",
		"-o", "ConnectionAttempts=1",
		userhost,
	}

	if port != "" {
		args = append(args, "-p", port)
	}

	s.Log.Debug("SSHing with command: ssh %s", strings.Join(args, " "))
	cmd := exec.Command("ssh", args...)
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
	Log   logging.Logger
	Debug bool

	// The *default* username used.
	RemoteUsername string

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
		RemoteCurrentUsername(req.CurrentUsernameOptions) (string, error)
		Tell(string, ...interface{}) (*dnode.Partial, error)
	}

	// Discover is used to resolve SSH address if klient connection is tunneled.
	Discover discover.Client
}

// GetSSHAddr returns the username and the hostname of the remove machine to ssh.
//
// It assume user exists on the remove machine with the same Koding username.
// It may also return a custom port number, if other than a default should
// be used.
func (s *SSHKey) GetSSHAddr(name string) (userhost, port string, err error) {
	infos, err := s.Klient.RemoteList()
	if err != nil {
		return "", "", err
	}

	info, ok := infos.FindFromName(name)

	if !ok {
		s.Log.Error("No machine found with specified name: `%s`", name)
		return "", "", ErrMachineNotFound
	}

	remoteUsername, err := s.GetUsername(name)
	if err != nil {
		return "", "", err
	}

	endpoints, err := s.Discover.Discover(info.IP, "ssh")
	if err != nil {
		return fmt.Sprintf("%s@%s", remoteUsername, info.IP), "", nil
	}

	addr := endpoints[0].Addr

	// We prefer local routes to use first, if there's none, we use first
	// discovered route.
	if e := endpoints.Filter(discover.ByLocal(true)); len(e) != 0 {

		// All local routes will do, typically there's only one,
		// we use the first one and ignore the rest.
		addr = e[0].Addr
	}

	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		host = addr
	}

	return fmt.Sprintf("%s@%s", remoteUsername, host), port, nil
}

// GetUsername returns the username of the remote machine.
func (s *SSHKey) GetUsername(name string) (username string, err error) {
	if s.RemoteUsername != "" {
		return s.RemoteUsername, nil
	}

	// Cache the return value if we have one. Not required, just useful,
	// no need for repeated queries.
	defer func() {
		if err == nil && username != "" {
			s.RemoteUsername = username
		}
	}()

	currentUsernameOpts := req.CurrentUsernameOptions{
		Debug:       s.Debug,
		MachineName: name,
	}

	return s.Klient.RemoteCurrentUsername(currentUsernameOpts)
}

// GenerateAndSaveKey generates a new SSH key pair and saves it to local.
func (s *SSHKey) GenerateAndSaveKey() ([]byte, error) {
	var perms os.FileMode = 0600

	if err := os.MkdirAll(filepath.Dir(s.PrivateKeyPath()), 0700); err != nil {
		return nil, err
	}

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

	username, err := s.GetUsername(name)
	if err != nil {
		return err
	}

	req := req.SSHKeyAdd{
		Debug:    s.Debug,
		Name:     name,
		Username: username,
		Key:      contents,
	}

	if _, err = s.Klient.Tell("remote.sshKeysAdd", req); err != nil {
		s.Log.Debug("Klient's remote.sshKeysAdd method returned err:%s", err)

		// ignore errors about duplicate keys since we're adding on each run
		if strings.Contains(err.Error(), "cannot add duplicate ssh key") {
			return nil
		}
	}

	return err
}
