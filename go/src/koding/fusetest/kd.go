package fusetest

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"koding/klient/remote/machine"
	"koding/klient/remote/restypes"
	"os"
	"os/exec"
	"strings"
	"time"
)

// KD is a simple struct for simplifying calling KD commands as a subprocess.
type KD struct {
	Stdout io.Writer
	Stderr io.Writer
	Stdin  io.Reader
}

// MountInfo is a customized struct to unmarshal the fields we care about from
// `kd list mounts`. Note that the actual struct returned by the command is
// the mount.Mount type, containing many fields.
//
// See `klient/remote/mount/mount.go` for reference if you want to add a field
// to this struct. Or simply type `kd list mounts --json` to see the json.
type MountInfo struct {
	IP               string `json:"ip"`
	Name             string `json:"name"`
	MountName        string `json:"mountName"`
	RemotePath       string `json:"remotePath"`
	LocalPath        string `json:"localPath"`
	NoIgnore         bool   `json:"noIgnore"`
	NoPrefetchMeta   bool   `json:"noPrefetchMeta"`
	PrefetchAll      bool   `json:"prefetchAll"`
	NoWatch          bool   `json:"noWatch"`
	CachePath        string `json:"cachePath"`
	OneWaySyncMount  bool   `json:"oneWaySyncMount"`
	SyncIntervalOpts struct {
		Interval time.Duration `json:"interval"`
	} `json:"syncIntervalOpts"`
}

func NewKD() *KD {
	return &KD{
		Stdout: os.Stdout,
		Stderr: os.Stderr,
		Stdin:  os.Stdin,
	}
}

func (kd *KD) GetMountOptions(mountName string) (MountInfo, error) {
	b, err := exec.Command("kd", "list", "mounts", "--json").CombinedOutput()
	if err != nil {
		return MountInfo{}, err
	}

	var mountsOpts []MountInfo
	if err := json.Unmarshal(b, &mountsOpts); err != nil {
		return MountInfo{}, err
	}

	for _, mountOpts := range mountsOpts {
		if mountOpts.MountName == mountName {
			return mountOpts, nil
		}
	}

	return MountInfo{}, errors.New("Mount not found.")
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

func (kd *KD) MountWithOneWaySync(machine, remoteDir, localDir string) error {
	return kd.run(
		"mount", "--oneway-sync", "--oneway-interval=1",
		joinWithColon(machine, remoteDir), localDir,
	)
}

func (kd *KD) MountWithPrefetchAll(machine, remoteDir, localDir string) error {
	return kd.run(
		"mount", "--prefetch-all", joinWithColon(machine, remoteDir), localDir,
	)
}

func (kd *KD) MountWithOpts(machine string, opts MountInfo) error {
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

	if opts.OneWaySyncMount {
		args = append(args, "--oneway-sync")
	}

	if opts.SyncIntervalOpts.Interval >= 0 {
		args = append(args, fmt.Sprintf(
			"--oneway-interval=%d", int(opts.SyncIntervalOpts.Interval.Seconds()),
		))
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
