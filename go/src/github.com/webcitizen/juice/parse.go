package juice

func Parse(content []byte) Rules {
	var letter byte

	state := new(State)

	for letter, content = stripLetter(content); letter != 0; letter, content = stripLetter(content) {
		state.parse(letter)
	}

	return state.rules
}


func ParseFile(path string) Rules {
	content := []byte(readFile(path))
	return Parse(content)
}
