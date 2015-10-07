package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func MustConfirm(help string) {
	fmt.Println(help)
	text, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		fmt.Printf("Unable to read from stdin: '%s'\n", err)
	}

	text = strings.TrimSpace(text)

	if text == "n" || text == "no" {
		fmt.Println("Please enter 'y' or 'yes'.")
		os.Exit(1)
	}

	if text != "" && text != "y" && text != "yes" {
		fmt.Println("Please enter 'y' or 'yes'.")
		os.Exit(1)
	}
}
