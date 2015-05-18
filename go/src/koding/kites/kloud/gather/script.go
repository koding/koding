package gather

type Script struct {
	Name string
	Path string
}

func (s *Script) Run() (Result, error) {
	return Result{"script": s.Name}, nil
}

type Result map[string]interface{}
