package runner

import (
	"fmt"
	"os"
	"strings"
	"syscall"
	"time"
)

var (
	startChannel  chan string
	stopChannel   chan bool
	closeChannel  chan bool
	changeChannel chan struct{}
	mainLog       logFunc
	watcherLog    logFunc
	runnerLog     logFunc
	buildLog      logFunc
	appLog        logFunc
)

func flushEvents() {
	for {
		select {
		case eventName := <-startChannel:
			mainLog("receiving event %s", eventName)
		default:
			return
		}
	}
}

func start() {
	loopIndex := 0
	buildDelay := buildDelay()

	started := false

	go func() {
		for {
			loopIndex++
			// eventName := <-startChannel
			<-startChannel

			// mainLog("receiving first event %s", eventName)
			// mainLog("sleeping for %d milliseconds", buildDelay)
			time.Sleep(buildDelay * time.Millisecond)
			// mainLog("flushing events")

			flushEvents()

			errorMessage, ok := build()
			if !ok {
				mainLog("Build Failed: \n %s", errorMessage)
				if !started {
					os.Exit(1)
				}
				createBuildErrorsLog(errorMessage)
			} else {
				if started {
					stopChannel <- true
				}
				run()
			}

			started = true
		}
	}()
}

func init() {
	startChannel = make(chan string, 1000)
	stopChannel = make(chan bool)
	closeChannel = make(chan bool)
	changeChannel = make(chan struct{})
}

func initLogFuncs() {
	mainLog = newLogFunc("main")
	watcherLog = func(string, ...interface{}) {}
	runnerLog = newLogFunc("runner")
	buildLog = newLogFunc("build")
	appLog = newLogFunc("app")
}

func initLimit() {
	var rLimit syscall.Rlimit
	rLimit.Max = 10000
	rLimit.Cur = 10000
	err := syscall.Setrlimit(syscall.RLIMIT_NOFILE, &rLimit)
	if err != nil {
		fmt.Println("Error Setting Rlimit ", err)
	}
}

func setEnvVars() {
	os.Setenv("DEV_RUNNER", "1")
	wd, err := os.Getwd()
	if err == nil {
		os.Setenv("RUNNER_WD", wd)
	}

	for k, v := range settings {
		key := strings.ToUpper(fmt.Sprintf("%s%s", envSettingsPrefix, k))
		os.Setenv(key, v)
	}
}

// Watches for file changes in the root directory.
// After each file system event it builds and (re)starts the application.
func Start() {
	initLimit()
	initSettings()
	initLogFuncs()
	initFolders()
	setEnvVars()
	watch()
	start()
	startChannel <- "/"

	<-closeChannel
}
