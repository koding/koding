package logging

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

func (c *context) New(prefix string) Logger {
	d := &context{
		prefix: c.prefix + "[" + prefix + "]",
	}
	d.logger = c.logger
	return d
}

func (c *context) prefixFormat() string {
	return c.prefix + " "
}
