package internet

import (
	"os"
	"os/exec"
)

func Disconnect() error {
	cmd := exec.Command("networksetup", "-setairportpower", "en0", "off")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

func Connect() error {
	cmd := exec.Command("networksetup", "-setairportpower", "en0", "on")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}
