package machine

import (
	"errors"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"koding/klient/machine/machinegroup"
	"koding/klientctl/ssh"
)

// SSHOptions stores options for `machine ssh` call.
type SSHOptions struct {
	Identifier string // Machine identifier.
	Username   string // Remote machine user to log as.

	AskList func(is, ds []string) (string, error) // Ask for multiple choices.
}

// SSH connects to remote machine using SSH protocol.
func (c *Client) SSH(options *SSHOptions) error {
	if options == nil {
		return errors.New("invalid nil options")
	}

	// Translate identifier to machine ID.
	id, err := c.getMachineID(options.Identifier, options.AskList)
	if err != nil {
		return err
	}

	pubKey, _, privPath, err := sshGetKeyPath()
	if err != nil {
		return err
	}

	// Add created key to authorized hosts on remote machine.
	sshReq := &machinegroup.SSHRequest{
		ID:        id,
		Username:  options.Username,
		PublicKey: pubKey,
	}
	var sshRes machinegroup.SSHResponse

	if err := c.klient().Call("machine.ssh", sshReq, &sshRes); err != nil {
		return err
	}

	// TODO(ppknap): move this to ssh package.
	args := []string{
		"-i", privPath,
		"-o", "StrictHostKeychecking=no",
		"-o", "UserKnownHostsFile=/dev/null",
		"-o", "ServerAliveInterval=300",
		"-o", "ServerAliveCountMax=3",
		"-o", "ConnectTimeout=7",
		"-o", "ConnectionAttempts=1",
		sshRes.Username + "@" + sshRes.Host,
	}

	if sshRes.Port > 0 {
		args = append(args, "-p", strconv.Itoa(sshRes.Port))
	}

	c.stream().Log().Info("Executing command: ssh %s", strings.Join(args, " "))
	cmd := exec.Command("ssh", args...)
	cmd.Stdin = c.stream().In()
	cmd.Stdout = c.stream().Out()
	cmd.Stderr = c.stream().Err()
	return cmd.Run()
}

// sshGetKeyPath gets local public key in case we need to copy it to remote
// machine. It also returns paths to public and private keys.
func sshGetKeyPath() (pubKey, pubPath, privPath string, err error) {
	path, err := ssh.GetKeyPath(nil)
	if err != nil {
		return "", "", "", err
	}

	pubPath, privPath, err = ssh.KeyPaths(path)
	if err != nil {
		return "", "", "", err
	}

	switch _, err := ssh.PrivateKey(privPath); err {
	case nil:
	case ssh.ErrPrivateKeyNotFound:
		// Private key is missing, remove the public one
		// to force keypair generation.
		//
		// TODO(rjeczalik): remove pubKey from remote
		_ = os.Remove(pubPath)
	default:
		return "", "", "", err
	}

	pubKey, err = ssh.PublicKey(pubPath)
	if err != nil && err != ssh.ErrPublicKeyNotFound {
		return "", "", "", err
	}

	// Generate new key pair if either public or private key does not exist.
	if err == ssh.ErrPublicKeyNotFound {
		if pubKey, _, err = ssh.GenerateSaved(pubPath, privPath); err != nil {
			return "", "", "", err
		}
	}

	return pubKey, pubPath, privPath, nil
}

// SSH connects to remote machine using SSH protocol using DefaultClient.
func SSH(opts *SSHOptions) error { return DefaultClient.SSH(opts) }
