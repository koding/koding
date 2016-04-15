package udnssdk

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
)

func Test_GeoDirectionalPoolKey_URI(t *testing.T) {
	want := "accounts/udnssdk/dirgroups/geo/unicorn"

	p := GeoDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	uri := p.URI()

	if uri != want {
		t.Errorf("URI: %+v, want: %+v", uri, want)
	}
}

func Test_GeoDirectionalPoolKey_QueryURI(t *testing.T) {
	want := "accounts/udnssdk/dirgroups/geo/unicorn?sort=NAME&query=rainbow&offset=1"

	p := GeoDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	uri := p.QueryURI("rainbow", 1)

	if uri != want {
		t.Errorf("QueryURI: %+v, want: %+v", uri, want)
	}
}

func Test_GeoDirectionalPoolKey_DirectionalPoolKey(t *testing.T) {
	want := DirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Type:    "geo",
		Name:    "unicorn",
	}

	p := GeoDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	dp := p.DirectionalPoolKey()

	if dp != want {
		t.Errorf("DirectionalPoolKey: %+v, want: %+v", dp, want)
	}
}

func Test_GeoDirectionalPoolsService_Select_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableDirectionalPoolTests {
		t.SkipNow()
	}
	if testAccounts == nil {
		t.Logf("No Accounts Present, skipping...")
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accountName := testAccounts[0].AccountName
	p := GeoDirectionalPoolKey{Account: AccountKey(accountName)}
	dpools, err := testClient.DirectionalPools.Geos().Select(p, "")

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Geo Pools: %v \n", dpools)
}

func Test_GeoDirectionalPoolsService_Select_Query_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableDirectionalPoolTests {
		t.SkipNow()
	}
	if testAccounts == nil {
		t.Logf("No Accounts Present, skipping...")
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accountName := testAccounts[0].AccountName
	p := GeoDirectionalPoolKey{Account: AccountKey(accountName)}
	dpools, err := testClient.DirectionalPools.Geos().Select(p, testQuery)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Geo Pools: %v \n", dpools)
}

func Test_GeoDirectionalPoolsService_Select(t *testing.T) {
	want := []AccountLevelGeoDirectionalGroupDTO{
		AccountLevelGeoDirectionalGroupDTO{
			Name:        "unicorn",
			Description: "unicorn: a service of rainbows",
			Codes:       []string{"US", "CA"},
		},
	}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := AccountLevelGeoDirectionalGroupListDTO{
			AccountName: "udnssdk",
			GeoGroups:   want,
			Queryinfo: QueryInfo{
				Q:       "unicorn",
				Sort:    "",
				Reverse: false,
				Limit:   0,
			},
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
	c, _ := newStubClient(testUsername, testPassword, ts.URL, "", "")

	p := GeoDirectionalPoolKey{Account: AccountKey("udnssdk")}
	ps, err := c.DirectionalPools.Geos().Select(p, "unicorn")

	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(ps, want) {
		t.Errorf("Geos: %+v, want: %+v", ps, want)
	}
}

func Test_GeoDirectionalPoolsService_Find_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableDirectionalPoolTests {
		t.SkipNow()
	}
	if testAccounts == nil {
		t.Logf("No Accounts Present, skipping...")
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accountName := testAccounts[0].AccountName
	p := GeoDirectionalPoolKey{
		Account: AccountKey(accountName),
		Name:    testIPDPool.Name,
	}
	dp, resp, err := testClient.DirectionalPools.Geos().Find(p)

	t.Logf("Test Get IP DPool Group (%s, %s)\n", testIPDPool.Name, testIPDPool)
	t.Logf("Response: %+v\n", resp.Response)
	t.Logf("DPool: %+v\n", dp)
	if err != nil {
		t.Logf("GetDirectionalPoolIP Error: %+v\n", err)
		if resp.Response.StatusCode == 404 {
			return
		}
		t.Fatal(err)
	}
	dp2, er := json.Marshal(dp)
	t.Logf("DPool Marshalled back: %s - %+v\n", string(dp2), er)
}

func Test_GeoDirectionalPoolsService_Find(t *testing.T) {
	want := AccountLevelGeoDirectionalGroupDTO{
		Name:        "unicorn",
		Description: "unicorn: a service of rainbows",
		Codes:       []string{"US", "CA"},
	}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := want

		mess, _ := json.Marshal(resp)
		fmt.Fprintln(w, string(mess))
	}))
	defer ts.Close()
	c, _ := newStubClient(testUsername, testPassword, ts.URL, "", "")

	p := GeoDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	a, _, err := c.DirectionalPools.Geos().Find(p)

	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(a, want) {
		t.Errorf("IPs: %+v, want: %+v", a, want)
	}
}

func Test_GeoDirectionalPoolsService_Create(t *testing.T) {
	t.SkipNow()
}

func Test_GeoDirectionalPoolsService_Update(t *testing.T) {
	t.SkipNow()
}

func Test_GeoDirectionalPoolService_Delete_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableDirectionalPoolTests {
		t.SkipNow()
	}
	if testAccounts == nil {
		t.Logf("No Accounts Present, skipping...")
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accountName := testAccounts[0].AccountName
	p := GeoDirectionalPoolKey{
		Account: AccountKey(accountName),
		Name:    testIPDPool.Name,
	}
	t.Logf("Delete(%+v)\n", p)
	resp, err := testClient.DirectionalPools.Geos().Delete(p)

	if err != nil {
		t.Logf("DeleteDirectionalPoolIP Error: %+v\n", err)
		if resp.Response.StatusCode == 404 {
			return
		}
		t.Fatal(err)
	}
	t.Logf("Response: %+v\n", resp.Response)
}

func Test_GeoDirectionalPoolsService_Delete(t *testing.T) {
	t.SkipNow()
}

func Test_IPDirectionalPoolKey_URI(t *testing.T) {
	want := "accounts/udnssdk/dirgroups/ip/unicorn"

	p := IPDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	uri := p.URI()

	if uri != want {
		t.Errorf("URI: %+v, want: %+v", uri, want)
	}
}

func Test_IPDirectionalPoolKey_QueryURI(t *testing.T) {
	want := "accounts/udnssdk/dirgroups/ip/unicorn?sort=NAME&query=rainbow&offset=1"

	p := IPDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	uri := p.QueryURI("rainbow", 1)

	if uri != want {
		t.Errorf("QueryURI: %+v, want: %+v", uri, want)
	}
}

func Test_IPDirectionalPoolKey_DirectionalPoolKey(t *testing.T) {
	want := DirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Type:    "ip",
		Name:    "unicorn",
	}

	p := IPDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	dp := p.DirectionalPoolKey()

	if dp != want {
		t.Errorf("DirectionalPoolKey: %+v, want: %+v", dp, want)
	}
}

func Test_IPDirectionalPoolService_Select_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableDirectionalPoolTests {
		t.SkipNow()
	}
	if !enableChanges {
		t.SkipNow()
	}
	if testAccounts == nil {
		t.Logf("No Accounts Present, skipping...")
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accountName := testAccounts[0].AccountName
	p := IPDirectionalPoolKey{Account: AccountKey(accountName)}
	dpools, err := testClient.DirectionalPools.IPs().Select(p, "")

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("IP Pools: %v \n", dpools)
}

func Test_IPDirectionalPoolService_Select_Query_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableDirectionalPoolTests {
		t.SkipNow()
	}
	if !enableChanges {
		t.SkipNow()
	}
	if testAccounts == nil {
		t.Logf("No Accounts Present, skipping...")
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accountName := testAccounts[0].AccountName
	p := IPDirectionalPoolKey{Account: AccountKey(accountName)}
	dpools, err := testClient.DirectionalPools.IPs().Select(p, testQuery)
	t.Logf("IP Pools: %v \n", dpools)

	if err != nil {
		t.Fatal(err)
	}
}

func Test_IPDirectionalPoolsService_Select(t *testing.T) {
	t.SkipNow()
}
func Test_IPDirectionalPoolsService_Find(t *testing.T) {
	want := AccountLevelIPDirectionalGroupDTO{
		Name:        "unicorn",
		Description: "unicorn: a service of rainbows",
		IPs: []IPAddrDTO{
			IPAddrDTO{Address: "1.2.3.4"},
		},
	}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := want

		mess, _ := json.Marshal(resp)
		fmt.Fprintln(w, string(mess))
	}))
	defer ts.Close()
	c, _ := newStubClient(testUsername, testPassword, ts.URL, "", "")

	p := IPDirectionalPoolKey{
		Account: AccountKey("udnssdk"),
		Name:    "unicorn",
	}
	a, _, err := c.DirectionalPools.IPs().Find(p)

	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(a, want) {
		t.Errorf("IPs: %+v, want: %+v", a, want)
	}
}

func Test_IPDirectionalPoolsService_Create_Live(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableDirectionalPoolTests {
		t.SkipNow()
	}
	if !enableChanges {
		t.SkipNow()
	}

	if testAccounts == nil {
		t.Logf("No Accounts Present, skipping...")
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	accountName := testAccounts[0].AccountName
	t.Logf("Creating %s with %+v\n", testIPDPool.Name, testIPDPool)
	p := IPDirectionalPoolKey{
		Account: AccountKey(accountName),
		Name:    testIPDPool.Name,
	}
	resp, err := testClient.DirectionalPools.IPs().Create(p, testIPDPool)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Response: %+v\n", resp.Response)
}

func Test_IPDirectionalPoolsService_Create(t *testing.T) {
	t.SkipNow()
}
func Test_IPDirectionalPoolsService_Update(t *testing.T) {
	t.SkipNow()
}
func Test_IPDirectionalPoolsService_Delete(t *testing.T) {
	t.SkipNow()
}
