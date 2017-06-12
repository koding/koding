package helper

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"

	"golang.org/x/crypto/ssh/terminal"
)

// Ask asks the user to enter an input
func Ask(format string, args ...interface{}) (string, error) {
	return Fask(os.Stdin, os.Stdout, format, args...)
}

// AskSecret asks the user to enter a password
func AskSecret(format string, args ...interface{}) (string, error) {
	return FaskSecret(os.Stdin, os.Stdout, format, args...)
}

// Fask asks the user to enter an input. It reads data from r and prints
// questions to w.
func Fask(r io.Reader, w io.Writer, format string, args ...interface{}) (string, error) {
	fmt.Fprintf(w, format, args...)
	s, err := bufio.NewReader(r).ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(s), nil
}

// FaskSecret asks the user to enter a passwor. It reads data from r and prints
// questions to w. Reader must be of *os.File type.
func FaskSecret(r io.Reader, w io.Writer, format string, args ...interface{}) (string, error) {
	f, ok := r.(*os.File)
	if !ok || f == nil {
		return "", fmt.Errorf("cannot read secrets from the reader (%T)", r)
	}

	fmt.Fprintf(w, format, args...)
	p, err := terminal.ReadPassword(int(f.Fd()))
	fmt.Fprintln(w)
	if err != nil {
		return "", err
	}
	return string(p), nil
}
