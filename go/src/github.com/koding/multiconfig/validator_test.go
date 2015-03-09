package multiconfig

import "testing"

func TestValidators(t *testing.T) {
	s := getDefaultServer()
	s.Name = ""

	err := (&RequiredValidator{}).Validate(s)
	if err == nil {
		t.Fatal("Name should be required")
	}
}

func TestValidatorsEmbededStruct(t *testing.T) {
	s := getDefaultServer()
	s.Postgres.Port = 0

	err := (&RequiredValidator{}).Validate(s)
	if err == nil {
		t.Fatal("Port should be required")
	}
}

func TestValidatorsCustomTag(t *testing.T) {
	s := getDefaultServer()

	validator := (&RequiredValidator{
		TagName:  "customRequired",
		TagValue: "yes",
	})

	// test happy path
	err := validator.Validate(s)
	if err != nil {
		t.Fatal(err)
	}

	// validate sad case
	s.Postgres.Port = 0
	err = validator.Validate(s)
	if err == nil {
		t.Fatal("Port should be required")
	}

	errStr := "multiconfig: field 'Postgres.Port' is required"
	if err.Error() != errStr {
		t.Fatalf("Err string is wrong: expected %s, got: %s", errStr, err.Error())
	}
}
