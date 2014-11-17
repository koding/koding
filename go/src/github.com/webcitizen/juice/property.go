package juice

type Property struct {
	Name  string
	Value string
}

func (p Property) String() string {
	return p.Name + ":" + p.Value + ";"
}
