package udnssdk

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
)

func Test_Accounts_Select_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableAccountTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accounts, resp, err := testClient.Accounts.Select()

	if err != nil {
		if resp.Response.StatusCode == 404 {
			t.SkipNow()
		}
		t.Fatal(err)
	}
	t.Logf("Accounts: %+v \n", accounts)
	t.Logf("Response: %+v\n", resp.Response)
}

func Test_Accounts_Select(t *testing.T) {
	want := []Account{
		Account{
			AccountName:           "terraform",
			AccountHolderUserName: "terraform",
			OwnerUserName:         "terraform",
			NumberOfUsers:         1,
			NumberOfGroups:        1,
			AccountType:           "ORGANIZATION",
		},
	}

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := AccountListDTO{
			Accounts: want,
			Resultinfo: ResultInfo{
				TotalCount:    len(want),
				Offset:        0,
				ReturnedCount: len(want),
			},
		}

		mess, _ := json.Marshal(resp)
		fmt.Fprintln(w, string(mess))
	}))
	defer ts.Close()

	testClient, _ := newStubClient(testUsername, testPassword, ts.URL, "", "")

	accounts, _, err := testClient.Accounts.Select()

	if err != nil {
		t.Fatal(err)
	}
	if len(accounts) != len(want) {
		t.Errorf("len(accounts): %+v, want: %+v", len(accounts), len(want))
	}
	for i, a := range accounts {
		w := want[i]
		if a != w {
			t.Errorf("accounts[%d]: %+v, want: %+v", i, a, w)
		}
	}
}

func Test_Accounts_Find(t *testing.T) {
	want := Account{
		AccountName:           "terraform",
		AccountHolderUserName: "terraform",
		OwnerUserName:         "terraform",
		NumberOfUsers:         1,
		NumberOfGroups:        1,
		AccountType:           "ORGANIZATION",
	}

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := want

		mess, _ := json.Marshal(resp)
		fmt.Fprintln(w, string(mess))
	}))
	defer ts.Close()

	testClient, _ := newStubClient(testUsername, testPassword, ts.URL, "", "")

	a, _, err := testClient.Accounts.Find("terraform")

	if err != nil {
		t.Fatal(err)
	}
	if a != want {
		t.Errorf("account: %+v, want: %+v", a, want)
	}
}

func Test_AccountsURI(t *testing.T) {
	uri := AccountsURI()
	want := "accounts"
	if uri != want {
		t.Errorf("AccountsURI: %+v, want: %+v", uri, want)
	}
}

func Test_Accounts_URI_empty(t *testing.T) {
	a := AccountKey("")
	want := "accounts"

	uri := a.URI()
	if uri != want {
		t.Errorf("AccountKey.URI: %+v, want: %+v", uri, want)
	}
}

func Test_Accounts_URI_nonempty(t *testing.T) {
	a := AccountKey("foo")
	want := "accounts/foo"

	uri := a.URI()
	if uri != want {
		t.Errorf("AccountKey.URI: %+v, want: %+v", uri, want)
	}
}
