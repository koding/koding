package helper

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"golang.org/x/crypto/ssh/terminal"
)

// Ask asks the user to enter an input
func Ask(format string, args ...interface{}) (string, error) {
	fmt.Printf(format, args...)
	s, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(s), nil
}

// AskSecret asks the user to enter a password
func AskSecret(format string, args ...interface{}) (string, error) {
	fmt.Printf(format, args...)
	p, err := terminal.ReadPassword(int(os.Stdin.Fd()))
	fmt.Println()
	if err != nil {
		return "", err
	}
	return string(p), nil
}
