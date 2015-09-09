package fs

import (
	"fmt"
	"os/exec"
)

func unmount(folder string) error {
	fmt.Println("Cleaning up...")

	if _, err := exec.Command("sudo", "umount", folder).CombinedOutput(); err != nil {
		fmt.Printf("Unmounting failed. Please do `sudo umount %s`.\n", folder)
	}

	return err
}
