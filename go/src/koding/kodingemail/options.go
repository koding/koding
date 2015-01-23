package kodingemail

type Options map[string]string

func (o Options) GetWithDefault(key string) string {
	value, ok := o[key]
	if !ok {
		return "default"
	}

	return value
}
