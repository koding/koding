package main

import (
	"koding/db/mongodb"
	"koding/tools/logger"

	"github.com/op/go-logging"
)

var (
	log                 *logging.Logger
	MAX_ITERATION_COUNT = 50
)

func init() {
	log = logger.CreateLogger("Profile Meta Counts Migrator", "debug")
}

func main() {

	err := mongodb.Run("jAccounts", updateFunc())
	if err != nil {
		log.Info("error on accouint query.", err)
	}
}
