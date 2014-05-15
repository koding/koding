package fat

import "testing"

func TestGenerateShortName(t *testing.T) {
	// Test a basic one with no used
	result, err := generateShortName("foo.bar", []string{})
	if err != nil {
		t.Fatalf("err should be nil: %s", err)
	}

	if result != "FOO.BAR" {
		t.Fatalf("unexpected: %s", result)
	}

	// Test long
	result, err = generateShortName("foobarbazblah.bar", []string{})
	if err != nil {
		t.Fatalf("err should be nil: %s", err)
	}

	if result != "FOOBAR~1.BAR" {
		t.Fatalf("unexpected: %s", result)
	}

	// Test weird characters
	result, err = generateShortName("foo*b?r?baz.bar", []string{})
	if err != nil {
		t.Fatalf("err should be nil: %s", err)
	}

	if result != "FOO_B_~1.BAR" {
		t.Fatalf("unexpected: %s", result)
	}

	// Test used
	result, err = generateShortName("foo.bar", []string{"foo.bar"})
	if err != nil {
		t.Fatalf("err should be nil: %s", err)
	}

	if result != "FOO~1.BAR" {
		t.Fatalf("unexpected: %s", result)
	}

	// Test without a dot
	result, err = generateShortName("BAM", []string{})
	if err != nil {
		t.Fatalf("err should be nil: %s", err)
	}

	if result != "BAM" {
		t.Fatalf("unexpected: %s", result)
	}
}
