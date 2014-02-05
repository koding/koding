package logger

type Level int

const (
	CRITICAL Level = iota
	ERROR
	WARNING
	NOTICE
	INFO
	DEBUG
)

var (
	// Mappings of strings in config file to internal types.
	nameToLevelMapping = map[string]Level{
		"critical": CRITICAL,
		"debug":    DEBUG,
		"error":    ERROR,
		"info":     INFO,
		"notice":   NOTICE,
		"warning":  WARNING,
	}

	// Default is always Warning, however the package can change it with SetLevel()
	DefaultLoggingLevel = WARNING

	// Stores current logging level.
	LogLevel Level
)

type Log interface {
	// Same as calling Critical() followed by a call to os.Exit(1).
	Fatal(args ...interface{})

	// Same as calling Critical() followed by a call to panic().
	Panic(format string, args ...interface{})

	Critical(format string, args ...interface{})
	Error(format string, args ...interface{})
	Warning(format string, args ...interface{})
	Notice(format string, args ...interface{})
	Info(format string, args ...interface{})
	Debug(format string, args ...interface{})

	// Recovers from panic and logs.
	RecoverAndLog()

	// Logs error with callstack.
	LogError(interface{}, int, ...interface{})

	Name() string

	SetLevel(level Level)
}

// Example:
//    var log = New("tester")
//    log.Info("Started")
func New(name string) Log {
	return NewGoLog(name)
}
