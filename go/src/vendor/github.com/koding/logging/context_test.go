package logging

import "testing"

func TestContext(t *testing.T) {
	var tds = []struct {
		expected string
		context  []interface{}
	}{
		{
			expected: "[prefix]",
			context:  []interface{}{"prefix"},
		},
		{
			expected: "[isEnabled=true][count=1233123123123][name=koding][standalone]",
			context: []interface{}{
				"isEnabled", true,
				"count", 1233123123123,
				"name", "koding",
				"standalone",
			},
		},
		{
			expected: "[isEnabled=true][count=1233123123123][name=koding][ratio=3.42323]",
			context: []interface{}{
				"isEnabled", true,
				"count", 1233123123123,
				"name", "koding",
				"ratio", 3.42323,
			},
		},
	}

	l := NewLogger("test")

	for _, td := range tds {
		contextedLogger := l.New(td.context...)
		if contextedLogger.(*context).prefix != td.expected {
			t.Fatalf("Prefix expected as %s, got: %s", td.expected, contextedLogger.(*context).prefix)
		}
	}
}
