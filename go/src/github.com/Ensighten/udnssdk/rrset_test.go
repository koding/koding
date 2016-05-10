package udnssdk

import (
	"encoding/json"
	"os"
	"strings"
	"testing"
)

func Test_RRSets_SelectPre(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if testClient == nil {
		t.Fatalf("TestClient Not Defined?\n")
	}
	if !enableRRSetTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "ANY",
		Name: testHostname,
	}
	t.Logf("Select(%v)", r)
	rrsets, err := testClient.RRSets.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("RRSets: %+v\n", rrsets)
}

func Test_RRSets_Select(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableRRSetTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "ANY",
		Name: "",
	}
	t.Logf("Select(%v)", r)
	rrsets, err := testClient.RRSets.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("RRSets: %+v\n", rrsets)
	t.Logf("Checking for profiles...\n")
	for _, rr := range rrsets {
		if rr.Profile != nil {
			typ := rr.Profile.Context()
			if typ == "" {
				t.Fatalf("Could not get type for profile %+v\n", rr.Profile)
			}
			t.Logf("Found Profile %s for %s\n", rr.Profile.Context(), rr.OwnerName)
			st, er := json.Marshal(rr.Profile)
			t.Logf("Marshal the profile to JSON: %s / %+v", string(st), er)
			t.Logf("Check the Magic Profile: %+v\n", rr.Profile.GetProfileObject())
		}
	}
}

func Test_RRSets_Create(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableRRSetTests {
		t.SkipNow()
	}
	if !enableChanges {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "A",
		Name: testHostname,
	}
	val := RRSet{
		OwnerName: r.Name,
		RRType:    r.Type,
		TTL:       300,
		RData:     []string{testIP1},
		Profile:   &StringProfile{Profile: testProfile},
	}
	t.Logf("Create(%v, %v)", r, val)
	resp, err := testClient.RRSets.Create(r, val)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Response: %+v\n", resp.Response)
}

// Another Get Test if it matchs the Ip in IP1
func Test_RRSets_SelectMid1(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableRRSetTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "ANY",
		Name: testHostname,
	}
	t.Logf("Select(%v)", r)
	rrsets, err := testClient.RRSets.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("RRSets: %+v\n", rrsets)
	// Do the test v IP1 here
	actual := rrsets[0].RData[0]
	expected := testIP1
	if actual != expected {
		t.Fatalf("actual RData[0]\"%s\" != expected \"%s\"", actual, expected)
	}
}

func Test_RRSets_Update(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableRRSetTests {
		t.SkipNow()
	}
	if !enableChanges {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "A",
		Name: testHostname,
	}
	val := RRSet{
		OwnerName: r.Name,
		RRType:    r.Type,
		TTL:       300,
		RData:     []string{testIP2},
		Profile:   &StringProfile{Profile: testProfile2},
	}
	t.Logf("Update(%v, %v)", r, val)
	resp, err := testClient.RRSets.Update(r, val)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Response: %+v\n", resp.Response)
}

// Another Get Test if it matches the Ip in IP2
func Test_RRSets_SelectMid(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableRRSetTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "ANY",
		Name: testHostname,
	}
	t.Logf("Select(%v)", r)
	rrsets, err := testClient.RRSets.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("RRSets: %+v\n", rrsets)
	// Do the test v IP2 here
	if rrsets[0].RData[0] != testIP2 {
		t.Fatalf("RData[0]\"%s\" != testIP2\"%s\"", rrsets[0].RData[0], testIP2)
	}
	t.Logf("Profile Check: %+v", rrsets[0].Profile.GetProfileObject())
}

func Test_RRSet_Delete(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableRRSetTests {
		t.SkipNow()
	}
	if !enableChanges {
		t.SkipNow()
	}
	if testHostname == "" ||
		testHostname[0] == '*' ||
		testHostname[0] == '@' ||
		testHostname == "www" ||
		testHostname[0] == '.' {
		t.Fatalf("Invalid testHostname defined: %v", testHostname)
		os.Exit(1)
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "ANY",
		Name: testHostname,
	}
	t.Logf("Select(%v)", r)
	rrsets, err := testClient.RRSets.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("RRSets: %+v\n", rrsets)
	for _, e := range rrsets {
		r := RRSetKey{
			Zone: testDomain,
			Type: e.RRType,
			Name: e.OwnerName,
		}
		if strings.Index(r.Type, " ") != -1 {
			t.Logf("Stripping whitespace rom Type: %v\n", r.Type)
			r.Type = strings.Fields(r.Type)[0]
		}
		t.Logf("Delete(%v)", r)
		resp, err := testClient.RRSets.Delete(r)
		t.Logf("Response: %+v\n", resp.Response)
		if err != nil {
			t.Fatal(err)
		}
	}
}

func Test_RRSet_SelectPost(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableRRSetTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testDomain,
		Type: "ANY",
		Name: testHostname,
	}
	t.Logf("Select(%v)", r)
	rrsets, err := testClient.RRSets.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("RRSets: %+v\n", rrsets)
}
