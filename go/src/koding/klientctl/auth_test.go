package main

import (
	"bytes"
	"encoding/json"
	"os"
	"reflect"
	"testing"

	"koding/kites/kloud/stack"
	"koding/klientctl/endpoint/team"
)

func TestAuthLogin(t *testing.T) {
	cases := map[string]struct {
		team *team.Team
		resp *stack.LoginResponse
	}{
		"foobar team": {
			&team.Team{Name: "foobar"},
			&stack.LoginResponse{
				GroupName: "foobar",
				Username:  "user",
				ClientID:  "abcd-efgh-ijk-lmn",
			},
		},
		"barbaz team": {
			&team.Team{Name: "barbaz"},
			&stack.LoginResponse{
				GroupName: "barbaz",
				Username:  "user",
				ClientID:  "abcd-efgh-ijk-lmn",
			},
		},
		"hebele team": {
			&team.Team{Name: "hebele"},
			&stack.LoginResponse{
				GroupName: "hebele",
				Username:  "user",
				ClientID:  "abcd-efgh-ijk-lmn",
			},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			var buf bytes.Buffer

			cmd := &MainCmd{
				Stdout: &buf,
				Stderr: os.Stderr,
			}

			cmd.FT.Add("kite.print", nil)
			cmd.FT.Add("auth.login", cas.resp)

			err := cmd.Run("auth", "login",
				"--team", cas.team.Name,
				"--json",
			)

			if err != nil {
				t.Fatalf("Run()=%s", err)
			}

			var got stack.LoginResponse

			if err := json.Unmarshal(buf.Bytes(), &got); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			if !reflect.DeepEqual(&got, cas.resp) {
				t.Fatalf("got %#v, want %#v", &got, cas.resp)
			}

			buf.Reset()

			err = cmd.Run("team", "show", "--json")

			var gotTeam team.Team

			if err := json.Unmarshal(buf.Bytes(), &gotTeam); err != nil {
				t.Fatalf("Unmarshal()=%s", err)
			}

			if !reflect.DeepEqual(&gotTeam, cas.team) {
				t.Fatalf("got %#v, want %#v", &got, cas.team)
			}
		})
	}
}
