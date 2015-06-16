package winrm

type Parameters struct {
	url          string
	Timeout      string
	Locale       string
	EnvelopeSize int
}

func DefaultParameters() *Parameters {
	return NewParameters("PT60S", "en-US", 153600)
}

func NewParameters(timeout string, locale string, envelopeSize int) *Parameters {
	return &Parameters{Timeout: timeout, Locale: locale, EnvelopeSize: envelopeSize}
}
