package rbd

import (
	"fmt"
	"koding/tools/config"
	"os/exec"
	"strconv"
	"syscall"
)

const RBDCmd = "/usr/bin/rbd"

type RBD struct {
	DevicePath string
	Image      string
	Pool       string
}

func NewRBD(image string) *RBD {
	pool := config.Current.VmPool
	if pool == "" {
		panic("rbd pool is not defined in config")
	}

	return &RBD{
		DevicePath: "/dev/rbd/" + pool + "/" + image,
		Image:      image,
		Pool:       pool,
	}
}

func (r *RBD) String() string {
	return r.DevicePath
}

func (r *RBD) Info() ([]byte, error) {
	args := []string{"info", "--pool", r.Pool, "--image", r.Image}

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

func (r *RBD) Create(sizeInMB int) ([]byte, error) {
	args := []string{"create", "--pool", r.Pool, "--size", strconv.Itoa(sizeInMB),
		"--image", r.Image, "--image-format", "1"}
	return r.executeRBDCommand(args)
}

func (r *RBD) Clone(snapshotName, destImage string) ([]byte, error) {
	args := []string{"clone", "--pool", r.Pool, "--image", r.Image,
		"--snap", snapshotName, "--dest-pool", r.Pool, "--dest", destImage}

	return r.executeRBDCommand(args)
}

func (r *RBD) Map() ([]byte, error) {
	args := []string{"map", "--pool", r.Pool, "--image", r.Image}
	return r.executeRBDCommand(args)
}

func (r *RBD) Unmap() ([]byte, error) {
	args := []string{"unmap", r.DevicePath}
	return r.executeRBDCommand(args)
}

func (r *RBD) Rm() ([]byte, error) {
	args := []string{"rm", "--pool", r.Pool, "--image", r.Image}
	return r.executeRBDCommand(args)
}

func (r *RBD) Resize(sizeInMB int) ([]byte, error) {
	args := []string{"resize", "--pool", r.Pool, "--image", r.Image, "--size",
		strconv.Itoa(sizeInMB)}
	return r.executeRBDCommand(args)
}

func (r *RBD) executeRBDCommand(args []string) ([]byte, error) {
	out, err := exec.Command(RBDCmd, args...).CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("rbd %s failed. err: %s\nout: %s\n", args[0], err, out)
	}

	return out, err
}
