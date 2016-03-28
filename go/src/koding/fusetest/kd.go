package fusetest

import (
	"fmt"
	"io"
	"os"
	"os/exec"
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

func (kd *KD) run(args ...string) error {
	cmd := exec.Command("kd", args...)
	// Assign stdout/etc for visible progress.
	cmd.Stdout = kd.Stdout
	cmd.Stderr = kd.Stderr
	cmd.Stdin = kd.Stdin
	if err := cmd.Run(); err != nil {
		return err
	}

	return nil
}

func (kd *KD) Mount(machine, remoteDir, localDir string) error {
	return kd.run("mount", fmt.Sprintf("%s:%s", machine, remoteDir), localDir)
}

func (kd *KD) MountWithNoPrefetch(machine, remoteDir, localDir string) error {
	return kd.run(
		"mount", "--noprefetch-meta", fmt.Sprintf("%s:%s", machine, remoteDir), localDir,
	)
}

func (kd *KD) MountWithPrefetchAll(machine, remoteDir, localDir string) error {
	return kd.run(
		"mount", "--prefetch-all", fmt.Sprintf("%s:%s", machine, remoteDir), localDir,
	)
}

func (kd *KD) Unmount(machine string) error {
	return kd.run("unmount", machine)
}
