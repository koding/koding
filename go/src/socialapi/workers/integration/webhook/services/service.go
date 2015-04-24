// services package is used for providing a Service interface. All the third
// party integrations need to implement this
package services

type Service interface {
	// PrepareMessage gets the input and prepares
	// the message body
	PrepareMessage(*ServiceInput) string

	// Validate incoming service input data
	Validate(*ServiceInput) []error

	// PrepareEndpoint prepares the endpoint url with given token
	PrepareEndpoint(string) string
}

// ServiceInput is used for input objects
type ServiceInput map[string]interface{}

func (si ServiceInput) Key(key string) interface{} {
	val, ok := map[string]interface{}(si)[key]
	if !ok {
		return nil
	}

	return val
}

func (si ServiceInput) SetKey(key string, value interface{}) {
	si[key] = value
}

