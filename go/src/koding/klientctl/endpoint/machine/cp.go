package machine

import (
	"context"
	"errors"
	"fmt"
	"os"

	"koding/klient/machine/machinegroup"
	"koding/klient/machine/transport/rsync"

	"github.com/koding/logging"
)

// CpOptions stores options for `machine cp` call.
type CpOptions struct {
	Download        bool   // Set to true when download from remote.
	Identifier      string // Machine identifier.
	SourcePath      string // Data source.
	DestinationPath string // Data destination.
	Log             logging.Logger
}

// Cp transfers file(s) between remote and local machine.
func (c *Client) Cp(options *CpOptions) (err error) {
	if options == nil {
		return errors.New("invalid nil options")
	}

	// Translate identifier to machine ID.
	idReq := &machinegroup.IDRequest{
		Identifier: options.Identifier,
	}
	var idRes machinegroup.IDResponse

	if err := c.klient().Call("machine.id", idReq, &idRes); err != nil {
		return err
	}

	// Ensure connection to remote machine.
	cpReq := &machinegroup.CpRequest{
		ID:              idRes.ID,
		Download:        options.Download,
		SourcePath:      options.SourcePath,
		DestinationPath: options.DestinationPath,
	}
	var cpRes machinegroup.CpResponse

	if err := c.klient().Call("machine.cp", cpReq, &cpRes); err != nil {
		return err
	}

	// Add private path to command.
	_, _, privPath, err := sshGetKeyPath()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Cannot copy requested data: %s\n", err)
		return err
	}

	cmd := cpRes.Command
	cmd.PrivateKeyPath = privPath
	cpRes.Command.PrivateKeyPath = privPath

	ctx := context.Background()

	fmt.Fprintf(os.Stdout, "Checking transfer size...\n")

	if n, size, err := cmd.DryRun(ctx); err != nil {
		c.log().Warning("Cannot obtain transfer size: %v", err)
		fmt.Fprintf(os.Stdout, "Copying files: remaining time is unknown\n")
	} else {
		cpRes.Command.Progress = rsync.Progress(os.Stdout, n, size)
	}

	return cpRes.Command.Run(ctx)
}

// Cp transfers file(s) between remote and local machine using DefaultClient.
func Cp(opts *CpOptions) error { return DefaultClient.Cp(opts) }
