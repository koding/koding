package kite

type ArgumentError struct {
	Expected string
}

func (err *ArgumentError) Error() string {
	return "Invalid argument, " + err.Expected + " expected."
}

type WrongChannelError struct{}

func (err *WrongChannelError) Error() string {
	return "Wrong channel."
}
