package azure

import (
	"testing"
)

func TestOAuthConfigForTenant(t *testing.T) {
	az := PublicCloud

	config, err := az.OAuthConfigForTenant("tenant-id-test")
	if err != nil {
		t.Errorf("autorest/azure: Unexpected error while retrieving oauth configuration for tenant: %v.", err)
	}

	expected := "https://login.microsoftonline.com/tenant-id-test/oauth2/authorize?api-version=1.0"
	if config.AuthorizeEndpoint.String() != expected {
		t.Errorf("autorest/azure: Incorrect authorize url for Tenant from Environment. expected(%s). actual(%s).", expected, config.AuthorizeEndpoint)
	}

	expected = "https://login.microsoftonline.com/tenant-id-test/oauth2/token?api-version=1.0"
	if config.TokenEndpoint.String() != expected {
		t.Errorf("autorest/azure: Incorrect authorize url for Tenant from Environment. expected(%s). actual(%s).", expected, config.TokenEndpoint)
	}

	expected = "https://login.microsoftonline.com/tenant-id-test/oauth2/devicecode?api-version=1.0"
	if config.DeviceCodeEndpoint.String() != expected {
		t.Errorf("autorest/azure: Incorrect devicecode url for Tenant from Environment. expected(%s). actual(%s).", expected, config.DeviceCodeEndpoint)
	}

}
