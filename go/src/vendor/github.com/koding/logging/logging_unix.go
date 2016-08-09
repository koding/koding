// +build darwin freebsd linux netbsd openbsd

package logging

func init() {
	StdoutHandler.Colorize = true
	StderrHandler.Colorize = true
}
