package topicmodifier

import (
	logging "github.com/op/go-logging"
	stdlog "log"
	"os"
)

var (
	log = logging.MustGetLogger("TopicModifier")
)

func init() {
	configureLogger()
}

func configureLogger() {
	logging.SetLevel(logging.INFO, "TopicModifier")
	log.Module = "TopicModifier"
	logging.SetFormatter(logging.MustStringFormatter("%{level:-3s} ▶ %{message}"))
	stderrBackend := logging.NewLogBackend(os.Stderr, "", stdlog.LstdFlags|stdlog.Lshortfile)
	stderrBackend.Color = true
	logging.SetBackend(stderrBackend)
}
