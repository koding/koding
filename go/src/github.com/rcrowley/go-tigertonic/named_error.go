package tigertonic

type NamedError interface {
	error
	Name() string
}
