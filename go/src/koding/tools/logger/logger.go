package logger

func New(name string) Log {
	return NewGoLog(name)
}

//----------------------------------------------------------
// Interface
//----------------------------------------------------------

type Log interface {
	Fatal(args ...interface{})
	Panic(format string, args ...interface{})
	Critical(format string, args ...interface{})
	Error(format string, args ...interface{})
	Warning(format string, args ...interface{})
	Notice(format string, args ...interface{})
	Info(format string, args ...interface{})
	Debug(format string, args ...interface{})
	RecoverAndLog()
	LogError(interface{}, int, ...interface{})
}
