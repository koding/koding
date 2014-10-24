package main

// type LoggedInUser struct {
//   Account       *models.Account
//   Machines      []*modelhelper.MachineContainer
//   Workspaces    []*models.Workspace
//   Group         *models.Group
//   Username      string
//   SessionId     string
//   Impersonating bool
// }

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

// Get returns value if exists, if not it returns the default value.
func (l *LoggedInUser) GetWithDefault(name, def string) interface{} {
	value, ok := l.Data[name]
	if !ok {
		return def
	}

	return value
}

func (l *LoggedInUser) Set(name string, value interface{}) {
	l.Data[name] = value
}
