package metrics

import (
	"strings"
	"testing"
)

func TestMultipleCmd(t *testing.T) {
	lsAndGrep := NewMultipleCmd(
		NewSingleCmd("ls", "-alh"),
		NewSingleCmd("grep", "Readme"),
	)

	bites, err := lsAndGrep.Run()
	if err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(string(bites), "Readme") {
		t.Errorf("No `Readme` found in results of `ls` cmd")
	}
}
