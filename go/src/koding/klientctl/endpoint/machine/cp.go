package machine

import (
	"errors"
	"fmt"
	"os"

	"koding/klient/machine/machinegroup"

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

	fmt.Fprintf(os.Stderr, "Response remote: %#v\n", cpRes)

	return nil
}

// Cp transfers file(s) between remote and local machine using DefaultClient.
func Cp(opts *CpOptions) error { return DefaultClient.Cp(opts) }
