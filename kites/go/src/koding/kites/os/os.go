package main

import (
	"fmt"
	"koding/tools/kite"
	"koding/tools/log"
	"math/rand"
	"os"
	"time"
)

func init() {
	rand.Seed(time.Now().UnixNano())
	log.Facility = fmt.Sprintf("os kite %d", os.Getpid())

	if os.Getuid() != 0 {
		panic("Must be run as root.")
	}
}

func main() {
	kite.Start("amqp://guest:x1srTA7!%25Vb%7D$n%7CS@web0.beta.system.aws.koding.com", "os", func(user, method string, args interface{}) interface{} {
		switch method {
		case "spawn":
			command := make([]string, 1+len(args.([]string)))
			command[0] = "/bin/lve_exec"
			copy(command[1:], args.([]string))
			return run(args.([]string), user)
		case "exec":
			return run([]string{"/bin/lve_exec", "/bin/bash", "-c", args.(string)}, user)
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
