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

func (l *LoggedInUser) GetOnlyValue(name string) interface{} {
	value, _ := l.Data[name]
	return value
}

func (l *LoggedInUser) Exists(name string) bool {
	_, ok := l.Data[name]
	return ok
}

func (l *LoggedInUser) Set(name string, value interface{}) {
	l.Data[name] = value
}
