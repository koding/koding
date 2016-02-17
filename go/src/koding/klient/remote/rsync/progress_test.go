package rsync

import (
	"os"
	"reflect"
	"testing"
)

func TestParseProgress(t *testing.T) {
	testDir := "testdata/download1.txt"
	download1, err := os.Open(testDir)
	if err != nil {
		t.Fatalf("Failed to open test file, err:%s", err)
	}
	defer download1.Close()

	progresses := []int{}
	for p := range ParseProgress(download1) {
		progresses = append(progresses, p)
	}

	expectedProgresses := []int{
		14647296,
		34242560,
		40984576,
		40986547,
		40988167,
		40989739,
		40999633,
		41001295,
	}

	if !reflect.DeepEqual(progresses, expectedProgresses) {
		t.Errorf(
			"Progresses from download1.txt did not parse properly. expected:%q, got:%q",
			expectedProgresses, progresses,
		)
	}
}

func TestParseProgressLine(t *testing.T) {
	_, err := ParseProgressLine("")
	if err != NotProgressableErr {
		t.Errorf("Expected an empty input to be NotProgressableErr. got:%s", err)
	}

	p, err := ParseProgressLine(
		"    40984576 100%    2.44MB/s    0:00:15 (xfer#1, to-check=5/7)",
	)
	if err != nil {
		t.Errorf("Encountered unexpected error. err:%s", err)
	}

	if p != 40984576 {
		t.Errorf("Unexpected progress result. wanted:%d, got:%d", 40984576, p)
	}

	_, err = ParseProgressLine("7 files to consider")
	if err != NotProgressableErr {
		t.Errorf("Expected an empty input to be NotProgressableErr. got:%s", err)
	}
}
