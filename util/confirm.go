package util

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
)

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

	text = strings.TrimSpace(text)
	text = strings.ToLower(text)

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
func YesNoConfirmWithDefault(r io.Reader, d bool) (bool, error) {
	text, err := bufio.NewReader(r).ReadString('\n')
	if err != nil {
		// TODO: Log this error, because it's strange.
		// log.Debug(fmt.Sprintf("Retry loop exited with err: '%s'", err.Error())
		return false, err
	}

	text = strings.TrimSpace(text)
	text = strings.ToLower(text)

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
