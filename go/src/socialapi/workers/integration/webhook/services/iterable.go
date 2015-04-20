package services

type Iterable struct {
}

func NewIterable() Iterable {
	return Iterable{}
}

func (i Iterable) PrepareMessage(input *ServiceInput) string {
	return ""
}

func (i Iterable) Validate(input *ServiceInput) []error {
	return []error{}
}

func (i Iterable) PrepareEndpoint(token string) string {
	return ""
}
