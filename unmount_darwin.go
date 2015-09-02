package main

import (
	"fmt"
	"os"
	"os/exec"
)

// unmount un mounts Fuse mounted local folder. Mount exists separate to
// lifecycle of this program and needs to be cleaned up when this exists.
func unmount(folder string) {
	fmt.Println("Cleaning up...")

	_, err := exec.Command("diskutil", "unmount", "force", folder).CombinedOutput()
	if err != nil {
		fmt.Printf("Unmount failed. Please do `diskutil unmount force %s`.\n", folder)
	}

	os.Exit(0)
}
