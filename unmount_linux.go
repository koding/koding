package fuseklient

import (
	"fmt"
	"os/exec"
)

// Unmount un mounts Fuse mounted local folder. Mount exists separate to
// lifecycle of this program and needs to be cleaned up when this exists.
func Unmount(folder string) error {
	if err := Unlock(k.MountPath); err != nil {
		return err
	}

	if _, err := exec.Command("sudo", "umount", "-l", folder).CombinedOutput(); err != nil {
		fmt.Printf("Unmounting failed. Please do `sudo umount %s`.\n", folder)
	}

	return nil
}
