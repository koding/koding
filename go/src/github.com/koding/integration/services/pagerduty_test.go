package services

import (
	"io"
	"strings"
	"testing"

	"github.com/koding/logging"
)

type fakeReadCloser struct {
	r io.Reader
}

func NewFakeReader(s string) *fakeReadCloser {
	reader := strings.NewReader(s)

	return &fakeReadCloser{
		r: reader,
	}

}
func (fakeReadCloser) Close() error { return nil }
func (f fakeReadCloser) Read(p []byte) (n int, err error) {
	return f.r.Read(p)
}

func TestPagerdutyReadbody(t *testing.T) {
	a := NewFakeReader(triggerData)
	pd := &PagerdutyActivity{}

	err := ReadAndParse(a, pd)
	if err != nil {
		return
	}

	d := ""
	for _, name := range pd.Messages {
		d = name.Type
	}
	exp := "incident.trigger"
	equals(t, exp, d)
}

func CreateTestPagerdutyService(t *testing.T) *Pagerduty {
	pd := Pagerduty{}
	pd.publicURL = "http://koding.com/api/webhook"
	pd.integrationURL = "http://koding.com/api/integration"
	pd.log = logging.NewLogger("testing")

	pc := &PagerdutyConfig{
		// ServerURL:      "",
		PublicURL:      pd.publicURL,
		IntegrationURL: pd.integrationURL,
	}

	service, err := NewPagerduty(pc, pd.log)
	if err != nil {
		t.Fatal(err)
	}

	return service
}

func TestPagerdutyCreateMessage(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.createMessage()

	exp := `>**Event**
Incident Triggered ([Datadog Service](https://koding-test.pagerduty.com/services/P1QP2YT))
**Subject**
datadesc
**Assigned To**
[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)
[View Incident Details](https://koding-test.pagerduty.com/incidents/PIVD27N)`
	equals(t, exp, d)
}

func TestTriggerPagerduty(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.trigger()
	exp := `>**Event**
Incident Triggered ([Datadog Service](https://koding-test.pagerduty.com/services/P1QP2YT))
**Subject**
datadesc
**Assigned To**
[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)
[View Incident Details](https://koding-test.pagerduty.com/incidents/PIVD27N)`
	equals(t, exp, d)
}

func TestAcknowledgePagerduty(t *testing.T) {
	pd, err := parsePagerdutyActivity(acknowledgeData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.acknowledge()
	exp := `>**Event**
Incident Acknowledged ([amazon](https://koding-test.pagerduty.com/services/POJ7I2R))
**Subject**
amadesc
**Assigned To**
[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)
[View Incident Details](https://koding-test.pagerduty.com/incidents/PWVXHR6)`
	equals(t, exp, d)
}

func TestResolvePagerduty(t *testing.T) {
	pd, err := parsePagerdutyActivity(resolveData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.resolve()
	exp := `>**Event**
Incident Resolved ([amazon](https://koding-test.pagerduty.com/services/POJ7I2R))
**Subject**
amadesc
**Assigned To**
[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)
[View Incident Details](https://koding-test.pagerduty.com/incidents/PWVXHR6)`
	equals(t, exp, d)
}

func TestUnacknowledgePagerduty(t *testing.T) {
	pd, err := parsePagerdutyActivity(unacknowledgeData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.unacknowledge()
	exp := `>**Event**
Incident Unacknowledged ([amazon](https://koding-test.pagerduty.com/services/POJ7I2R))
**Subject**
amazon desc.
**Assigned To**
[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)
[View Incident Details](https://koding-test.pagerduty.com/incidents/PD0MLVP)`
	equals(t, exp, d)
}

func TestAssignPagerduty(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.assign()
	exp := `>**Event**
Incident Assigned ([Datadog Service](https://koding-test.pagerduty.com/services/P1QP2YT))
**Subject**
datadesc
**Assigned To**
[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)
**Description**
This service was created during onboarding on August 25, 2015.`
	equals(t, exp, d)
}

func TestEscalatePagerduty(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.escalate()
	exp := `>**Event**
Incident Escalated ([Datadog Service](https://koding-test.pagerduty.com/services/P1QP2YT))
**Assigned To**
[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)
**Description**
This service was created during onboarding on August 25, 2015.`
	equals(t, exp, d)
}

func TestGetType(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getType()
	exp := "incident.trigger"
	equals(t, exp, d)

}

func TestGetServiceName(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getServiceName()
	exp := "Datadog Service"
	equals(t, exp, d)

}

func TestGetServiceURL(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getServiceURL()
	exp := "https://koding-test.pagerduty.com/services/P1QP2YT"
	equals(t, exp, d)

}

func TestGetSubject(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getSubject()
	exp := "datadesc"
	equals(t, exp, d)

}

func TestGetAssignedTo(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getAssignedTo()
	exp := "[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)"
	equals(t, exp, d)

}

func TestGetResolvedBy(t *testing.T) {
	pd, err := parsePagerdutyActivity(resolveData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getResolvedBy()
	exp := "[Mehmet Ali](https://koding-test.pagerduty.com/users/PWGTT51)"
	equals(t, exp, d)

}

func TestGetDescription(t *testing.T) {
	pd, err := parsePagerdutyActivity(triggerData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getDescription()
	exp := "This service was created during onboarding on August 25, 2015."
	equals(t, exp, d)

}

func TestGetIncidentURL(t *testing.T) {
	pd, err := parsePagerdutyActivity(resolveData)
	if err != nil {
		t.Fatalf(err.Error())
	}
	d := pd.getIncidentURL()
	exp := "https://koding-test.pagerduty.com/incidents/PWVXHR6"
	equals(t, exp, d)

}

func parsePagerdutyActivity(body string) (*PagerdutyActivity, error) {
	a := NewFakeReader(body)
	pd := &PagerdutyActivity{}

	err := ReadAndParse(a, pd)
	if err != nil {
		return nil, err
	}

	return pd, nil
}
