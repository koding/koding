package tests

import (
	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
)

func TestGenerateTestFuncs(t *testing.T) {
	t.Skip("not implemented yet")
	common.RunTest(t, &Generator{}, testdata.JSON1, expecteds)
}

var expecteds = []string{``, ``}
