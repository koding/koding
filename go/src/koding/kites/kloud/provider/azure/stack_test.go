package azure_test

import (
	"flag"
	"testing"

	"koding/kites/kloud/provider/azure"
)

var update = flag.Bool("update-golden", false, "Update golden files.")

var publishSettings = `<?xml version="1.0" encoding="utf-8"?>
<PublishData>
  <PublishProfile
    SchemaVersion="2.0"
    PublishMethod="AzureServiceManagementAPI">
    <Subscription
      ServiceManagementUrl="https://management.core.windows.net"
      Id="aa3ed1eb-ff8c-4312-b2f9-11cf611563b4"
      Name="Pay-As-You-Go"
      ManagementCertificate="..." />
    <Subscription
      ServiceManagementUrl="https://management.core.windows.net"
      Id="8a523531-2d66-469d-9228-718ad2a58eff"
      Name="Free Trial"
      ManagementCertificate="..." />
  </PublishProfile>
</PublishData>
`

func TestAzureMeta_PublishSettings(t *testing.T) {
	cases := map[string]struct {
		meta  *azure.Cred
		valid bool
	}{
		"valid Free Trial": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
				SubscriptionID:  "8a523531-2d66-469d-9228-718ad2a58eff",
			},
			valid: true,
		},
		"valid Pay-As-You-Go": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
				SubscriptionID:  "aa3ed1eb-ff8c-4312-b2f9-11cf611563b4",
			},
			valid: true,
		},
		"missing subscription ID": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
			},
			valid: false,
		},
		"invalid subscription ID": {
			meta: &azure.Cred{
				PublishSettings: publishSettings,
				SubscriptionID:  "invalid",
			},
			valid: false,
		},
	}

	for desc, cas := range cases {
		err := cas.meta.Valid()

		if cas.valid && err != nil {
			t.Fatalf("%s: got %# v, want nil", desc, err)
		}

		if !cas.valid && err == nil {
			t.Fatalf("%s: got nil, want non-nil error", desc)
		}
	}
}
