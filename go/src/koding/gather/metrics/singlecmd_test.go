package metrics

import (
	"strings"
	"testing"
)

func TestSingleCmd(t *testing.T) {
	ls := NewSingleCmd("ls", "-al")

	bites, err := ls.Run()
	if err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(string(bites), "Readme") {
		t.Errorf("No `Readme` found in results of `ls` cmd")
	}

	if !strings.Contains(string(bites), "total") {
		t.Errorf("No `total` found in results of `ls` cmd")
	}
}
