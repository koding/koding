package main

import (
	"bufio"
	"fmt"
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
