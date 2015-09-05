package unmount

import (
	"fmt"
	"os"
	"os/exec"
)

// Unmount un mounts Fuse mounted local folder. Mount exists separate to
// lifecycle of this program and needs to be cleaned up when this exists.
func Unmount(folder string) {
	fmt.Println("Cleaning up...")

	if _, err := exec.Command("sudo", "umount", folder).CombinedOutput(); err != nil {
		fmt.Printf("Unmounting failed. Please do `sudo umount %s`.\n", folder)
	}

	os.Exit(0)
}
