package main

type LoggedInUser struct {
	Data map[string]interface{}
}

func NewLoggedInUser() *LoggedInUser {
	return &LoggedInUser{Data: map[string]interface{}{}}
}

func (l *LoggedInUser) Get(name string) (interface{}, bool) {
	value, ok := l.Data[name]
	return value, ok
}

// Get returns value if exists, if not it returns empty string
func (l *LoggedInUser) GetWithDefaultStr(name string) interface{} {
	value, ok := l.Data[name]
	if !ok {
		return ""
	}

	return value
}

// Get returns value if exists, if not it returns empty hash
func (l *LoggedInUser) GetWithDefaultHash(name string) interface{} {
	value, ok := l.Data[name]
	if !ok {
		return map[string]interface{}{}
	}

	return value
}

func (l *LoggedInUser) Set(name string, value interface{}) {
	l.Data[name] = value
}
