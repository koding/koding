package vagrant

import (
	"testing"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/hashicorp/terraform/terraform"
)

var testVagrantResourceProviders map[string]terraform.ResourceProvider
var testVagrantProvider *schema.Provider

func init() {
	testVagrantProvider = Provider().(*schema.Provider)
	testVagrantResourceProviders = map[string]terraform.ResourceProvider{
		"vagrant": testVagrantProvider,
	}
}

func TestProvider(t *testing.T) {
	if err := Provider().(*schema.Provider).InternalValidate(); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestProvider_impl(t *testing.T) {
	var _ terraform.ResourceProvider = Provider()
}

func testAccPreCheck(t *testing.T) {}
