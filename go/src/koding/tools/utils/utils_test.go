package utils_test

import (
	"fmt"
	"testing"

	"koding/tools/utils"
)

func TestPwgenChars(t *testing.T) {
	cases := []int{2, 4, 5, 7, 8, 20, 50}

	for _, n := range cases {
		// capture range variable here
		n := n
		t.Run(fmt.Sprintf("%d-character long password", n), func(t *testing.T) {
			t.Parallel()
			pw := utils.Pwgen(n)

			t.Logf("%s", pw)

			if len(pw) != n {
				t.Fatalf("got len(pw)=%d, want %d", len(pw), n)
			}
		})
	}
}
