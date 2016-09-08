package mailgun

import (
	"testing"
)

func TestGetStats(t *testing.T) {
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	mg := NewMailgun(domain, apiKey, "")

	totalCount, stats, err := mg.GetStats(-1, -1, nil, "sent", "opened")
	if err != nil {
		t.Fatal(err)
	}

	t.Logf("Total Count: %d\n", totalCount)
	t.Logf("Id\tEvent\tCreatedAt\tTotalCount\t\n")
	for _, stat := range stats {
		t.Logf("%s\t%s\t%s\t%d\t\n", stat.Id, stat.Event, stat.CreatedAt, stat.TotalCount)
	}
}

func TestDeleteTag(t *testing.T) {
	domain := reqEnv(t, "MG_DOMAIN")
	apiKey := reqEnv(t, "MG_API_KEY")
	mg := NewMailgun(domain, apiKey, "")
	err := mg.DeleteTag("newsletter")
	if err != nil {
		t.Fatal(err)
	}
}
