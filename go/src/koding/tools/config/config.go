package config

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
)

type Config struct {
	ProjectRoot string
	GoConfig    struct {
		HomePrefix string
		UseLVE     bool
	}
	Mq struct {
		Host          string
		ComponentUser string
		Password      string
	}
	Loggr struct {
		Push   bool
		Url    string
		ApiKey string
	}
	Librato struct {
		Push     bool
		Email    string
		Token    string
		Interval int
	}
}

var Current Config

func LoadConfig(profile string) {
	j, err := exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+profile+"')").CombinedOutput()
	if err != nil {
		fmt.Printf("Could execute Koding config manager: %s\n", err.Error())
		os.Exit(1)
	}

	if err := json.Unmarshal(j, &Current); err != nil {
		fmt.Printf("Koding config manager output:\n%s\nCould not unmarshal config: %s\n", j, err.Error())
		os.Exit(1)
	}
}
