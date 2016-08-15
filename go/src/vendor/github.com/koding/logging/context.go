package logging

import "fmt"

type context struct {
	prefix string
	logger
}

// Fatal is equivalent to Critical() followed by a call to os.Exit(1).
func (c *context) Fatal(format string, args ...interface{}) {
	c.logger.Fatal(c.prefixFormat()+format, args...)
}

// Panic is equivalent to Critical() followed by a call to panic().
func (c *context) Panic(format string, args ...interface{}) {
	c.logger.Panic(c.prefixFormat()+format, args...)
}

// Critical sends a critical level log message to the handler. Arguments are
// handled in the manner of fmt.Printf.
func (c *context) Critical(format string, args ...interface{}) {
	c.logger.Critical(c.prefixFormat()+format, args...)
}

// Error sends a error level log message to the handler. Arguments are handled
// in the manner of fmt.Printf.
func (c *context) Error(format string, args ...interface{}) {
	c.logger.Error(c.prefixFormat()+format, args...)
}

// Warning sends a warning level log message to the handler. Arguments are
// handled in the manner of fmt.Printf.
func (c *context) Warning(format string, args ...interface{}) {
	c.logger.Warning(c.prefixFormat()+format, args...)
}

// Notice sends a notice level log message to the handler. Arguments are
// handled in the manner of fmt.Printf.
func (c *context) Notice(format string, args ...interface{}) {
	c.logger.Notice(c.prefixFormat()+format, args...)
}

// Info sends a info level log message to the handler. Arguments are handled in
// the manner of fmt.Printf.
func (c *context) Info(format string, args ...interface{}) {
	c.logger.Info(c.prefixFormat()+format, args...)
}

// Debug sends a debug level log message to the handler. Arguments are handled
// in the manner of fmt.Printf.
func (c *context) Debug(format string, args ...interface{}) {
	c.logger.Debug(c.prefixFormat()+format, args...)
}

// New creates a new Logger from current context
func (c *context) New(prefixes ...interface{}) Logger {
	return newContext(c.logger, c.prefix, prefixes...)
}

func (c *context) prefixFormat() string {
	return c.prefix + " "
}

func newContext(logger logger, initial string, prefixes ...interface{}) *context {
	resultPrefix := "" // resultPrefix holds prefix after initialization
	connector := ""    // connector holds the connector string

	for _, prefix := range prefixes {
		resultPrefix += fmt.Sprintf("%s%+v", connector, prefix)
		switch connector {
		case "=": // if previous is `=` replace with ][
			connector = "]["
		case "][": // if previous is `][` replace with =
			connector = "="
		default:
			connector = "=" // if its first iteration, assing =
		}
	}

	return &context{
		prefix: initial + "[" + resultPrefix + "]",
		logger: logger,
	}

}
