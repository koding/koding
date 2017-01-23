package main

import (
	"bytes"
	"encoding/json"
	"os"
	"reflect"
	"testing"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/team"
)

func TestTeamList(t *testing.T) {
	cases := map[string]struct {
		args     []string
		expected []*team.Team
	}{
		"all teams": {
			nil,
			[]*team.Team{
				&team.Team{Name: "teamA", Slug: "teamAS", Privacy: "public", SubStatus: "paid"},
				&team.Team{Name: "teamB", Slug: "teamBS", Privacy: "private", SubStatus: "trailing"},
			},
		},
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			var buf bytes.Buffer

			cmd := &MainCmd{
				Stdout: &buf,
				Stderr: os.Stderr,
			}

			cmd.FT.Add("team.list", stack.TeamListResponse{Teams: cas.expected})

			args := []string{"team", "list", "--json"}

			err := cmd.Run(append(args, cas.args...)...)
			if err != nil {
				t.Fatalf("Run()=%s", err)
			}

			var got []*team.Team
			if err := json.Unmarshal(buf.Bytes(), &got); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			if !reflect.DeepEqual(got, cas.expected) {
				t.Fatalf("got %#v, want %#v", got, cas.expected)
			}
		})
	}
}
