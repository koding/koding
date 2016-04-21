package fusetest

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"koding/klient/remote/machine"
	"koding/klient/remote/req"
	"koding/klient/remote/restypes"
	"os"
	"os/exec"
	"strings"
)

// KD is a simple struct for simplifying calling KD commands as a subprocess.
type KD struct {
	Stdout io.Writer
	Stderr io.Writer
	Stdin  io.Reader
}

func NewKD() *KD {
	return &KD{
		Stdout: os.Stdout,
		Stderr: os.Stderr,
		Stdin:  os.Stdin,
	}
}

func (kd *KD) GetMountOptions(mountName string) (req.MountFolder, error) {
	b, err := exec.Command("kd", "list", "mounts", "--json").CombinedOutput()
	if err != nil {
		return req.MountFolder{}, err
	}

	var mountsOpts []req.MountFolder
	if err := json.Unmarshal(b, &mountsOpts); err != nil {
		return req.MountFolder{}, err
	}

	for _, mountOpts := range mountsOpts {
		if mountOpts.Name == mountName {
			return mountOpts, nil
		}
	}

	return req.MountFolder{}, errors.New("Mount not found.")
}

func (kd *KD) GetMachineInfo(machineName string) (restypes.ListMachineInfo, error) {
	b, err := exec.Command("kd", "list", "--json").CombinedOutput()
	if err != nil {
		return restypes.ListMachineInfo{}, err
	}

	var infos []restypes.ListMachineInfo
	if err := json.Unmarshal(b, &infos); err != nil {
		return restypes.ListMachineInfo{}, err
	}

	for _, info := range infos {
		if machineName == info.VMName {
			return info, nil
		}
	}

	return restypes.ListMachineInfo{}, errors.New("Mount not found.")
}

func (kd *KD) GetMachineStatus(machineName string) (machine.MachineStatus, error) {
	info, err := kd.GetMachineInfo(machineName)
	return info.MachineStatus, err
}

func (kd *KD) run_cmd(c string, args ...string) error {
	cmd := exec.Command(c, args...)
	// Assign stdout/etc for visible progress.
	cmd.Stdout = kd.Stdout
	cmd.Stderr = kd.Stderr
	cmd.Stdin = kd.Stdin

	return cmd.Run()
}

func (kd *KD) run(args ...string) error {
	return kd.run_cmd("kd", args...)
}

func (kd *KD) Mount(machine, remoteDir, localDir string) error {
	return kd.run("mount", joinWithColon(machine, remoteDir), localDir)
}

func (kd *KD) MountWithNoPrefetch(machine, remoteDir, localDir string) error {
	return kd.run(
		"mount", "--noprefetch-meta", joinWithColon(machine, remoteDir), localDir,
	)
}

func (kd *KD) MountWithPrefetchAll(machine, remoteDir, localDir string) error {
	return kd.run(
		"mount", "--prefetch-all", joinWithColon(machine, remoteDir), localDir,
	)
}

func (kd *KD) MountWithOpts(machine string, opts req.MountFolder) error {
	args := []string{"mount"}
	if opts.NoWatch {
		args = append(args, "--nowatch")
	}

	if opts.PrefetchAll {
		args = append(args, "--prefetch-all")
	}

	if opts.NoPrefetchMeta {
		args = append(args, "--noprefetch-meta")
	}

	if opts.NoIgnore {
		args = append(args, "--noignore")
	}

	args = append(args, joinWithColon(machine, opts.RemotePath), opts.LocalPath)
	return kd.run(args...)
}

func (kd *KD) Unmount(machine string) error {
	return kd.run("unmount", machine)
}

func (kd *KD) Restart() error {
	// Printing a newline here, incase sudo asks the caller for password.
	// If we don't, they might not see it, due to Convey.
	fmt.Println("")
	return kd.run_cmd("sudo", "kd", "restart")
}

func joinWithColon(s ...string) string {
	return strings.Join(s, ":")
}
