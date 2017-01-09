package stack

func FixHCL(v interface{})              { fixHCL(v) }
func FixYAML(v interface{}) interface{} { return fixYAML(v) }
