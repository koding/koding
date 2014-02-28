package oskite

import (
	"koding/tools/config"
	"koding/tools/logger"
	logg "log"
	"os"
	"strconv"
	"testing"
	"time"
)

var (
	Profile = "vagrant"
	Region  = "vagrant"
	VMLimit = 100
	Timeout = time.Minute * 50
)

func TestOskite(t *testing.T) {
	OverrideConfig()

	o := New(config.MustConfig(Profile))

	o.PrepareQueueLimit = 8 + 1
	o.LogLevel = logger.DEBUG
	o.Region = Region
	o.ActiveVMsLimit = VMLimit
	o.VmTimeout = time.Minute * 50

	go o.Run()

}

func OverrideConfig() {
	envProfile := os.Getenv("PROFILE")
	if envProfile != "" {
		Profile = envProfile
	}

	envRegion := os.Getenv("REGION")
	if envRegion != "" {
		Region = envRegion
	}

	envLimit := os.Getenv("LIMIT")
	if envLimit != "" {
		limit, err := strconv.Atoi(envLimit)
		if err != nil {
			logg.Printf("Limit couldn't be parsed: %s. Using 100 as maximum VM limit.\n", err.Error())
		} else {
			VMLimit = limit
		}
	}

	envTimeout := os.Getenv("TIMEOUT")
	if envTimeout != "" {
		timeout, err := time.ParseDuration(envTimeout)
		if err != nil {
			logg.Printf("Timeout is wrong: %s. Using standart timeout\n", err.Error())
			Timeout = time.Minute * 50
		} else {
			Timeout = timeout
		}
	}

}
