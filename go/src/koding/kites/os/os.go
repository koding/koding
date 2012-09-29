package main

import (
	"koding/tools/kite"
	"koding/tools/utils"
)

func main() {
	utils.DefaultStartup("os kite", true)

	kite.Run("os", func(user, method string, args interface{}) (error, interface{}) {
		switch method {
		case "spawn":
			array, ok := args.([]interface{})
			if !ok {
				return &kite.ArgumentError{"array of strings"}, nil
			}
			command := make([]string, len(array))
			for i, entry := range array {
				command[i], ok = entry.(string)
				if !ok {
					return &kite.ArgumentError{"array of strings"}, nil
				}
			}
			return run(command, user)
		case "exec":
			line, ok := args.(string)
			if !ok {
				return &kite.ArgumentError{"string"}, nil
			}
			return run([]string{"/bin/bash", "-c", line}, user)
		}
		return &kite.UnknownMethodError{method}, nil
	})
}

func run(command []string, user string) (error, string) {
	cmd := kite.CreateCommand(command, user)
	output, err := cmd.CombinedOutput()
	return err, string(output)
}
