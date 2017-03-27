package machinegroup

import (
	"errors"
	"time"

	"koding/klient/machine"
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
	// AbsRemotePath stores absolute representation of remote path.
	AbsRemotePath string `json:"absRemotePath"`

	// Test TODO
	Test string `json:"test"`
}

// Cp creates rsync command used for copying files between local machine and
// remote one.
func (g *Group) Cp(req *CpRequest) (*CpResponse, error) {
	if req == nil {
		return nil, errors.New("invalid nil request")
	}

	// Add SSH public key to remote machine's authorized_keys file. This is
	// needed for rsync SSH connection.
	errC := g.sshKey(req.ID, 30*time.Second)

	// absRemotePath, count, diskSize, err := c.MountHeadIndex(req.Mount.RemotePath)
	// if err != nil {
	// 	return nil, err
	// }

	// Wait for remote machine SSH key upload.
	if err := <-errC; err != nil {
		return nil, err
	}

	res := &CpResponse{
		AbsRemotePath: "Path",
		Test:          "This is a test",
	}

	return res, nil
}
