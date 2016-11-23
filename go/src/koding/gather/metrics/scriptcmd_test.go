package metrics

import (
	"io/ioutil"
	"strings"
	"testing"
)

func TestScriptCmd(t *testing.T) {
	lsCmd := []byte("ls $1")

	filename := "/tmp/ls"
	err := ioutil.WriteFile(filename, lsCmd, 0644)
	if err != nil {
		t.Fatal(err)
	}

	lsCmdScript := NewScriptCmd(filename, "-alh")

	bites, err := lsCmdScript.Run()
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
