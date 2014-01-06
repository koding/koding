package topicmodifier

import (
	logging "github.com/op/go-logging"
	"koding/tools/config"
	"koding/tools/logger"
)

var log *logging.Logger

func init() {
	level := config.Current.TopicModifier.LogLevel
	log = logger.CreateLogger("TopicModifier", level)

}
