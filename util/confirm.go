package util

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strings"
)

// trimAndLower simply trims, and lower cases the given string
func trimAndLower(s string) string {
	s = strings.TrimSpace(s)
	return strings.ToLower(s)
}

// MustConfirm asks users to confirm if they want to continue. It defaults to
// Y if user press enter without entering anything. `y` and `yes` are the other
// acceptable answers. Any other answer will result in exit with 1 code.
func MustConfirm(help string) {
	fmt.Print(help)

	text, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		fmt.Printf("Unable to read from stdin: '%s'\n", err)
		os.Exit(1)
	}

	text = trimAndLower(text)

	if text == "n" || text == "no" {
		fmt.Println("Please enter 'y' or 'yes'.")
		os.Exit(1)
	}

	if text != "" && text != "y" && text != "yes" {
		fmt.Println("Please enter 'y' or 'yes'.")
		os.Exit(1)
	}
}

// YesNoConfirmWithDefault reads from the given reader for a line, and
// simply returns true/false based on a yes/no input.
//
// If an empty line is supplied (ie, `"\n"`), the supplied value is
// used as default.
//
// TODO: Find a way to mock Stdin, so that we can pass in a generic Reader
// here and not an explicit bufio.Reader. To understand why this problem
// exists, here is a description of the problem:
//
// askToCreate calls YesNoConfirmWithDefault() multiple times, with a
// single reader instance (os.Stdin). If you mock this stdin with a
// bytes.Buffer, then this functions use of:
//
// 		bufio.NewReader(r).ReadString('\n')
//
// will cause the bytes.Buffer to be drained completely on the first
// YesNo confirm. Subsequent YesNo attempts on the same Reader will
// only see an empty bytes.Buffer, because the first bufio.Reader drained
// the entire bytes.Buffer. We need to figure a way to mock Stdin,
// so that it can be not greedy.
func YesNoConfirmWithDefault(r *bufio.Reader, d bool) (bool, error) {
	text, err := r.ReadString('\n')
	if err != nil {
		// TODO: Log this error, because it's strange.
		// log.Debug(fmt.Sprintf("Retry loop exited with err: '%s'", err.Error())
		return false, err
	}

	text = trimAndLower(text)

	switch text {
	case "":
		return d, nil
	case "y", "yes":
		return true, nil
	case "n", "no":
		return false, nil
	default:
		return false, errors.New(fmt.Sprintf("Not accepted input '%s'", text))
	}
}
