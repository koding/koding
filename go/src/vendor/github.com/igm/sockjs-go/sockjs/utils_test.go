package sockjs

import (
	"encoding/json"
	"strconv"
	"testing"
)

func TestQuote(t *testing.T) {
	var quotationTests = []struct {
		input  string
		output string
	}{
		{"simple", "\"simple\""},
		{"more complex \"", "\"more complex \\\"\""},
	}

	for _, testCase := range quotationTests {
		if quote(testCase.input) != testCase.output {
			t.Errorf("Expected '%s', got '%s'", testCase.output, quote(testCase.input))
		}
	}
}

func TestQuote_StrconvKiller(t *testing.T) {
	var killer = `{"寔愆샠5]䗄IH贈=d﯊/偶?ॊn%晥D視N򗘈'᫂⚦|X쵩넽z질tskxDQ莮Aoﱻ뛓":true}`

	var cases = map[string]struct {
		quote func(string) string
		ok    bool
	}{
		"quote":         {quote, true},
		"strconv.Quote": {strconv.Quote, false},
	}

	for name, cas := range cases {
		var s string
		var p = []byte(cas.quote(killer))

		err := json.Unmarshal(p, &s)

		if cas.ok && err != nil {
			t.Fatalf("%s: Unmarshal()=%s", name, err)
		}

		if !cas.ok && err == nil {
			t.Fatalf("%s: wanted Unmarshal to fail", name)
		}
	}
}
