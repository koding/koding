package common

import (
	"encoding/json"
	"testing"

	"github.com/cihangir/schema"
)

// RunTest provides a basic test runner for gene packages
func RunTest(t *testing.T, g Generator, testData string, expecteds []string) {
	s := &schema.Schema{}
	if err := json.Unmarshal([]byte(testData), s); err != nil {
		t.Fatal(err.Error())
	}

	s = s.Resolve(s)

	req := &Req{
		Schema:  s,
		Context: NewContext(),
	}
	res := &Res{}
	err := g.Generate(req, res)
	if err != nil {
		t.Fatal(err.Error())
	}

	if res.Output == nil {
		t.Fatal("output is nil")
	}

	for i, s := range res.Output {
		TestEquals(t, expecteds[i], string(s.Content))
	}
}
