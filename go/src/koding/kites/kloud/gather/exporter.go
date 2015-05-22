package gather

type Exporter interface {
	SendResult([]interface{}, Options) error
	SendError(error, Options) error
}
