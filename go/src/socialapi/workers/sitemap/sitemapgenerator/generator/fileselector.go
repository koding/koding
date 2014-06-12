package generator

type FileSelector interface {
	Select() string
}

type SimpleFileSelector struct{}

func (s SimpleFileSelector) Select() string {
	return "firstfile.xml"
}
