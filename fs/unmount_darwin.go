package fs

import (
	"fmt"
	"os/exec"
)

func unmount(folder string) error {
	_, err := exec.Command("diskutil", "unmount", "force", folder).CombinedOutput()
	if err != nil {
		fmt.Printf("Unmounting failed. Please do `diskutil unmount force %s`.\n", folder)
	}

	return err
}
