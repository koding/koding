package machine

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"koding/klient/machine/machinegroup"
	"koding/klientctl/klient"
	"koding/klientctl/ssh"

	"github.com/koding/logging"
)

// SSHOptions stores options for `machine ssh` call.
type SSHOptions struct {
	Identifier string // Machine identifier.
	Username   string // Remote machine user to log as.
	Log        logging.Logger
}

// SSH connects to remote machine using SSH protocol.
func SSH(options *SSHOptions) error {
	// Translate identifier to machine ID.
	//
	// TODO(ppknap): this is copied from klientctl old list and will be reworked.
	k, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating klient:", err)
		return err
	}

	if err := k.Dial(); err != nil {
		fmt.Fprintln(os.Stderr, "Error dialing klient:", err)
		return err
	}

	idReq := machinegroup.IDRequest{
		Identifier: options.Identifier,
	}
	idRaw, err := k.Tell("machine.id", idReq)
	if err != nil {
		return err
	}
	idRes := machinegroup.IDResponse{}
	if err := idRaw.Unmarshal(&idRes); err != nil {
		return err
	}

	// Get local public key in case we need to copy it to remote machine.
	path, err := ssh.GetKeyPath(nil)
	if err != nil {
		return err
	}

	pubPath, privPath, err := ssh.KeyPaths(path)
	if err != nil {
		return err
	}

	pubkey, err := ssh.PublicKey(pubPath)
	if err != nil && err != ssh.ErrPublicKeyNotFound {
		return err
	}

	// Generate new key pair if it does not exist.
	if err == ssh.ErrPublicKeyNotFound {
		if pubkey, _, err = ssh.GenerateSaved(pubPath, privPath); err != nil {
			return err
		}
	}

	// Add created key to authorized hosts on remote machine.
	sshReq := machinegroup.SSHRequest{
		ID:        idRes.ID,
		Username:  options.Username,
		PublicKey: pubkey,
	}
	sshRaw, err := k.Tell("machine.ssh", sshReq)
	if err != nil {
		return err
	}
	sshRes := machinegroup.SSHResponse{}
	if err := sshRaw.Unmarshal(&sshRes); err != nil {
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

	options.Log.Info("Executing command: ssh %s", strings.Join(args, " "))
	cmd := exec.Command("ssh", args...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	return cmd.Run()
}
