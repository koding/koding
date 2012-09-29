package main

import (
	"fmt"
	"koding/tools/kite"
	"koding/tools/utils"
)

func main() {
	utils.DefaultStartup("os kite", true)

	kite.Run("amqp://guest:x1srTA7!%25Vb%7D$n%7CS@web0.beta.system.aws.koding.com", "os", func(user, method string, args interface{}) interface{} {
		switch method {
		case "spawn":
			return run(args.([]string), user)
		case "exec":
			return run([]string{"/bin/bash", "-c", args.(string)}, user)
		default:
			panic(fmt.Sprintf("Unknown method: %v.", method))
		}
		return nil
	})
}

func run(command []string, user string) string {
	cmd := kite.CreateCommand(command, user, "/Users/")
	output, err := cmd.CombinedOutput()
	if err != nil {
		panic(err)
	}
	return string(output)
}
