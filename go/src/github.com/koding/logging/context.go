package logging

// type context struct {
// 	id interface{}
// 	logger
// }

// // NewLogger returns a new Logger implementation. Do not forget to close it at exit.
// func NewContext(logger logger, id interface{}) Logger {
// 	return context{
// 		id:     id,
// 		logger: logger,
// 	}
// }

// // Fatal is equivalent to Critical() followed by a call to os.Exit(1).
// func (c *context) Fatal(format string, args ...interface{}) {
// 	c.logger.Fatal("[%v]"+format, id, args...)
// }

// // Panic is equivalent to Critical() followed by a call to panic().
// func (c *context) Panic(format string, args ...interface{}) {
// 	c.logger.Panic("[%v]"+format, id, args...)
// }

// // Critical sends a critical level log message to the handler. Arguments are handled in the manner of fmt.Printf.
// func (c *context) Critical(format string, args ...interface{}) {
// 	c.logger.Critical("[%v]"+format, id, args...)
// }

// // Error sends a error level log message to the handler. Arguments are handled in the manner of fmt.Printf.
// func (c *context) Error(format string, args ...interface{}) {
// 	c.logger.Error("[%v]"+format, id, args...)
// }

// // Warning sends a warning level log message to the handler. Arguments are handled in the manner of fmt.Printf.
// func (c *context) Warning(format string, args ...interface{}) {
// 	c.logger.Warning("[%v]"+format, id, args...)
// }

// // Notice sends a notice level log message to the handler. Arguments are handled in the manner of fmt.Printf.
// func (c *context) Notice(format string, args ...interface{}) {
// 	c.logger.Notice("[%v]"+format, id, args...)
// }

// // Info sends a info level log message to the handler. Arguments are handled in the manner of fmt.Printf.
// func (c *context) Info(format string, args ...interface{}) {
// 	c.logger.Info("[%v]"+format, id, args...)
// }

// // Debug sends a debug level log message to the handler. Arguments are handled in the manner of fmt.Printf.
// func (c *context) Debug(format string, args ...interface{}) {
// 	c.logger.Debug("[%v]"+format, id, args...)
// }
