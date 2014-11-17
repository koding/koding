package juice

import (
	"bytes"
	"strings"
)

type State struct {
	state           byte
	commentState    byte
	current         []byte
	previous        []byte
	currentRule     Rule
	currentProperty Property
	rules           Rules
}

// Error constants
const (
	NOT_IN_SELECTOR = "Met { while not being in selector"
	NOT_AFTER_VALUE = "Met } after a non-value"
	NOT_IN_PROPERTY = "Met : after a non-property"
	NOT_IN_VALUE    = "Met ; after a non-value"
)

// Parser constants
const (
	STARTING_COMMENT = iota
	IN_COMMENT       = iota
	CLOSING_COMMENT  = iota
	COMMENT_CLOSED   = iota
	IN_SELECTOR      = iota
	IN_PROPERTY      = iota
	IN_VALUE         = iota
)

func (s *State) parse(letter byte) {
	switch letter {
	case '/':
		s.slash(letter)
	case '*':
		s.star(letter)
	case '{':
		s.openBracket(letter)
	case '}':
		s.closeBracket(letter)
	case ':':
		s.colon(letter)
	case ';':
		s.semicolon(letter)
	default:
		s.rest(letter)
	}
}

func (s *State) slash(letter byte) {
	switch s.commentState {
	case CLOSING_COMMENT:
		// Since we don't keep comments
		s.current = s.previous
		s.commentState = COMMENT_CLOSED
	default:
		if s.commentState != IN_COMMENT {
			s.commentState = STARTING_COMMENT
			s.current = append(s.current, letter)
		}
	}
}

func (s *State) star(letter byte) {
	switch s.commentState {
	case STARTING_COMMENT:
		s.previous = s.current[:len(s.current)-1]
		s.commentState = IN_COMMENT
		s.current = append(s.current, letter)
	case IN_COMMENT:
		s.commentState = CLOSING_COMMENT
		s.current = append(s.current, letter)
	}

}

func (s *State) openBracket(letter byte) {
	if s.commentState != IN_COMMENT {
		if s.state == IN_SELECTOR {
			s.state = IN_PROPERTY
			s.currentRule.Selector = clean(s.current)
			s.current = []byte{}
		} else {
			panic(NOT_IN_SELECTOR)
		}
	}
}

func (s *State) closeBracket(letter byte) {
	if s.commentState != IN_COMMENT {
		if s.state == IN_VALUE && !bytes.Equal(nil, s.current) {
			s.state = IN_PROPERTY
			s.currentProperty.Value = string(s.current)
			s.currentRule.Properties = append(s.currentRule.Properties, s.currentProperty)
		}
		if s.state == IN_PROPERTY && strings.Trim(string(s.current), " ") != "" {
			s.current = []byte{}
			s.rules = append(s.rules, s.currentRule)
			s.currentRule = Rule{}
			s.state = IN_SELECTOR
		} else {
			panic(NOT_AFTER_VALUE)
		}
	}
}

func (s *State) colon(letter byte) {
	if s.commentState != IN_COMMENT {
		if s.state == IN_PROPERTY && !bytes.Equal(nil, s.current) {
			s.state = IN_VALUE
			s.currentProperty.Name = clean(s.current)

			// Cleanup
			s.current = []byte{}
		} else {
			if s.state != IN_VALUE && s.state != IN_SELECTOR {
				panic(NOT_IN_PROPERTY)
			}

			// If there, it means we're in a value
			s.current = append(s.current, letter)
		}
	}
}

func (s *State) semicolon(letter byte) {
	if s.commentState != IN_COMMENT {
		if s.state == IN_VALUE {
			s.state = IN_PROPERTY
			s.currentProperty.Value = string(s.current)
			s.currentRule.Properties = append(s.currentRule.Properties, s.currentProperty)

			// Cleanup
			s.currentProperty = Property{}
			s.current = []byte{}
		} else {
			panic(NOT_IN_VALUE)
		}
	}
}

func (s *State) rest(letter byte) {
	if s.commentState != IN_COMMENT {
		if s.state == 0 {
			s.state = IN_SELECTOR
		}
		s.current = append(s.current, letter)
	}
}
