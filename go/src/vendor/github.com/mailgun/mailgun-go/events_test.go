package mailgun

import (
	"testing"
)

func TestEventIterator(t *testing.T) {
	// Grab the list of events (as many as we can get)
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	mg := NewMailgun(domain, apiKey, "")
	ei := mg.NewEventIterator()
	err := ei.GetFirstPage(GetEventsOptions{})
	if err != nil {
		t.Fatal(err)
	}

	// Print out the kind of event and timestamp.
	// Specifics about each event will depend on the "event" type.
	events := ei.Events()
	t.Log("Event\tTimestamp\t")
	for _, event := range events {
		t.Logf("%s\t%v\t\n", event["event"], event["timestamp"])
	}
	t.Logf("%d events dumped\n\n", len(events))

	// We're on the first page.  We must at the beginning.
	ei.GetPrevious()
	if len(ei.Events()) != 0 {
		t.Fatal("Expected to be at the beginning")
	}
}
