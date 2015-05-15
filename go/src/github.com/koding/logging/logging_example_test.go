package logging

import (
	"fmt"
	"os"
)

type exampleFormatter struct{}

func (f *exampleFormatter) Format(rec *Record) string {
	return fmt.Sprintf("%-8s [%-4s] %s",
		LevelNames[rec.Level],
		rec.LoggerName,
		fmt.Sprintf(rec.Format, rec.Args...),
	)
}

func ExampleContexted() {
	// Custom logger with new std out handler
	l := NewLogger("test")
	l.SetLevel(DEBUG)

	// create handler
	logHandler := NewWriterHandler(os.Stdout)
	logHandler.SetLevel(DEBUG)
	logHandler.Formatter = &exampleFormatter{}
	// set handler
	l.SetHandler(logHandler)

	// Custom logger with inherited handler
	ctx1 := l.New("example")
	ctx1.Debug("Debug")

	// derive new one from previous contexted
	ctx2 := ctx1.New("debug", true, "level", 2, "example")
	ctx2.Debug("Debug")

	// create new context inline
	ctx1.New("standalone").Debug("Debug")

	// Output:
	//DEBUG    [test] [example] Debug
	//DEBUG    [test] [example][debug=true][level=2][example] Debug
	//DEBUG    [test] [example][standalone] Debug
}
