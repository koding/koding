package fuseklient

import "os/exec"

func unmount(folder string) error {
	_, err := exec.Command("diskutil", "unmount", "force", folder).CombinedOutput()
	return err
}
