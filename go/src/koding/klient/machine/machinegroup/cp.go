package machinegroup

import (
	"errors"
	"time"

	"fmt"
	"koding/klient/machine"
	"koding/klient/machine/transport/rsync"
)

// CpRequest defines machine group cp request.
type CpRequest struct {
	// ID is a unique identifier for the remote machine.
	ID machine.ID `json:"id"`

	// Download is set to true when remote machine is a source of data.
	Download bool `json:"download"`

	// SourcePath defines data source.
	SourcePath string `json:"sourcePath"`

	// DestinationPath defines data destination.
	DestinationPath string `json:"destinationPath"`
}

// CpResponse defines machine group head cp response.
type CpResponse struct {
	// Command stores a valid rsync command that must be run in order to
	// perform file copying.
	Command rsync.Command `json:"command"`
}

// Cp creates rsync command used for copying files between local machine and
// remote one.
func (g *Group) Cp(req *CpRequest) (*CpResponse, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	// If we download file, then source path is on remote machine.
	remotePath := req.SourcePath
	if !req.Download {
		remotePath = req.DestinationPath
	}

	// Add SSH public key to remote machine's authorized_keys file. This is
	// needed for rsync SSH connection.
	ruC := g.sshKey(req.ID, 30*time.Second)

	c, err := g.client.Client(req.ID)
	if err != nil {
		return nil, err
	}

	absRemotePath, _, exist, err := c.Abs(remotePath)
	if err != nil {
		return nil, err
	}

	// We cannot download file/dir that doesn't exist.
	if !exist && req.Download {
		return nil, fmt.Errorf("remote source %q does not exist", absRemotePath)
	}

	// Put absolute path back to source or destination.
	if req.Download {
		req.SourcePath = absRemotePath
	} else {
		req.DestinationPath = absRemotePath
	}

	host, port, err := g.dynamicSSH(req.ID)()
	if err != nil {
		return nil, err
	}

	// Wait for remote machine SSH key upload.
	ru := <-ruC
	if err := ru.Err; err != nil {
		return nil, err
	}

	res := &CpResponse{
		Command: rsync.Command{
			Download:        req.Download,
			SourcePath:      req.SourcePath,
			DestinationPath: req.DestinationPath,
			Username:        ru.Username,
			Host:            host,
			SSHPort:         port,
		},
	}

	return res, nil
}
