package fusetest

import (
	"io"
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

func (kd *KD) run(args ...string) error {
	cmd := exec.Command("kd", args...)
	// Assign stdout/etc for visible progress.
	cmd.Stdout = kd.Stdout
	cmd.Stderr = kd.Stderr
	cmd.Stdin = kd.Stdin

	return cmd.Run()
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

func (kd *KD) Unmount(machine string) error {
	return kd.run("unmount", machine)
}

func joinWithColon(s ...string) string {
	return strings.Join(s, ":")
}
