// +build cobra

package main

import (
	"koding/klientctl/commands"
)

func main() {
	commands.KdCmd.Execute()
}
