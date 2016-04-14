package udnssdk

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func Test_GetProbeAlerts(t *testing.T) {
	if !enableIntegrationTests {
		t.SkipNow()
	}
	if !enableProbeTests {
		t.SkipNow()
	}

	testClient, err := NewClient(testUsername, testPassword, testBaseURL)
	if err != nil {
		t.Fatal(err)
	}

	r := RRSetKey{
		Zone: testProbeDomain,
		Type: testProbeType,
		Name: testProbeName,
	}
	alerts, err := testClient.Alerts.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Probe Alerts: %+v \n", alerts)
}

func Test_Alerts_Select(t *testing.T) {
	want := []ProbeAlertDataDTO{
		ProbeAlertDataDTO{
			PoolRecord:      "1.2.3.4",
			ProbeType:       "DNS",
			ProbeStatus:     "Failed",
			AlertDate:       time.Now(),
			FailoverOccured: true,
			OwnerName:       "foo.basedomain.example",
			Status:          "Active",
		},
	}
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		resp := ProbeAlertDataListDTO{
			Alerts: want,
			Queryinfo: QueryInfo{
				Q:       "",
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
	testClient, _ := newStubClient(testUsername, testPassword, ts.URL, "", "")

	r := RRSetKey{
		Zone: "basedomain.example",
		Type: "A",
		Name: "foo",
	}
	alerts, err := testClient.Alerts.Select(r)

	if err != nil {
		t.Fatal(err)
	}
	if len(alerts) != len(want) {
		t.Errorf("len(alerts): %+v, want: %+v", len(alerts), len(want))
	}
	for i, a := range alerts {
		w := want[i]
		if a != w {
			t.Errorf("alerts[%d]: %+v, want: %+v", i, a, w)
		}
	}
}
