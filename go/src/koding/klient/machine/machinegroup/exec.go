package machinegroup

import (
	"errors"
	"path/filepath"

	"koding/klient/machine"
	"koding/klient/os"
)

type MachineRequest struct {
	MachineID machine.ID `json:"machineID"`
	Path      string     `json:"path"`
}

func (r *MachineRequest) Valid() error {
	if r.MachineID == "" && r.Path == "" {
		return errors.New("both path and machine ID are empty")
	}
	if r.Path != "" && !filepath.IsAbs(r.Path) {
		return errors.New("invalid relative path")
	}
	return nil
}

type ExecRequest struct {
	os.ExecRequest
	MachineRequest
}

func (r *ExecRequest) Valid() error {
	if err := r.ExecRequest.Valid(); err != nil {
		return err
	}
	return r.MachineRequest.Valid()
}

type ExecResponse struct {
	os.ExecResponse
}

type KillRequest struct {
	os.KillRequest
	MachineRequest
}

func (r *KillRequest) Valid() error {
	if err := r.KillRequest.Valid(); err != nil {
		return err
	}
	return r.MachineRequest.Valid()
}

type KillResponse struct {
	os.KillResponse
}

func (g *Group) Exec(r *ExecRequest) (*ExecResponse, error) {
	return nil, nil
}

func (g *Group) Kill(r *KillRequest) (*KillResponse, error) {
	return nil, nil
}
