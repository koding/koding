package rbd

import (
	"fmt"
	"koding/tools/config"
	"os/exec"
	"syscall"
)

const RBDCmd = "/usr/bin/rbd"

type RBD struct {
	Device string
	Pool   string
}

func NewRBD(device string) *RBD {
	pool := config.Current.VmPool
	if pool == "" {
		panic("rbd pool is not defined in config")
	}

	return &RBD{
		Device: "/dev/rbd/" + pool + "/" + device,
		Pool:   pool,
	}
}

func (r *RBD) String() string {
	return r.Device
}

func (r *RBD) Info(image string) ([]byte, error) {
	args := []string{"info", "--pool", r.Pool, "--image", image}

	out, err := exec.Command(RBDCmd, args...).CombinedOutput()
	if err != nil {
		exitError, isExitError := err.(*exec.ExitError)
		if !isExitError || exitError.Sys().(syscall.WaitStatus).ExitStatus() != 1 {
			return nil, fmt.Errorf("rbd info failed. err: %s\nout: %s\n", err, out)
		}

		return nil, nil // means there is no image
	}

	return out, nil
}

func (r *RBD) Create(image, sizeInMB string) ([]byte, error) {
	args := []string{"create", "--pool", r.Pool, "--size", sizeInMB,
		"--image", image, "--image-format", "1"}
	return r.executeRBDCommand(args)
}

func (r *RBD) Clone(image, snapshotName, destImage string) ([]byte, error) {
	args := []string{"clone", "--pool", r.Pool, "--image", image,
		"--snap", snapshotName, "--dest-pool", r.Pool, "--dest", destImage}

	return r.executeRBDCommand(args)
}

func (r *RBD) Map(image string) ([]byte, error) {
	args := []string{"map", "--pool", r.Pool, "--image", image}
	return r.executeRBDCommand(args)
}

func (r *RBD) Unmap() ([]byte, error) {
	args := []string{"unmap", r.Device}
	return r.executeRBDCommand(args)
}

func (r *RBD) Rm(image string) ([]byte, error) {
	args := []string{"rm", "--pool", r.Pool, "--image", image}

	return r.executeRBDCommand(args)
}

func (r *RBD) executeRBDCommand(args []string) ([]byte, error) {
	out, err := exec.Command(RBDCmd, args...).CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("rbd %s failed. err: %s\nout: %s\n", args[0], err, out)
	}

	return out, err
}
