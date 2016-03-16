package fuseklient

import "os/exec"

// Unmount un mounts Fuse mounted local folder. Mount exists separate to
// lifecycle of this program and needs to be cleaned up when this exists.
func Unmount(folder string) error {
	_, err := exec.Command("diskutil", "unmount", "force", folder).CombinedOutput()
	return err
}
