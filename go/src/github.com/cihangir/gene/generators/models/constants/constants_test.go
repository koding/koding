package constants

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestConstants(t *testing.T) {
	s := &schema.Schema{}
	if err := json.Unmarshal([]byte(testdata.JSON1), s); err != nil {
		t.Fatal(err.Error())
	}

	s = s.Resolve(nil)

	a, err := Generate(s.Definitions["Account"])
	common.TestEquals(t, nil, err)
	common.TestEquals(t, expected, string(a))
}

const expected = `
	// AccountEmailStatusConstant holds the predefined enums
	var AccountEmailStatusConstant = struct {
		Verified    string
		NotVerified string
	}{
		Verified:    "verified",
		NotVerified: "notVerified",
	}

	// AccountPasswordStatusConstant holds the predefined enums
	var AccountPasswordStatusConstant = struct {
		Valid      string
		NeedsReset string
		Generated  string
	}{
		Valid:      "valid",
		NeedsReset: "needsReset",
		Generated:  "generated",
	}

	// AccountStatusConstant holds the predefined enums
	var AccountStatusConstant = struct {
		Registered              string
		Unregistered            string
		NeedsManualVerification string
	}{
		Registered:              "registered",
		Unregistered:            "unregistered",
		NeedsManualVerification: "needsManualVerification",
	}`
