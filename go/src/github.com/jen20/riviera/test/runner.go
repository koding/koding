package test

import (
	"fmt"
	"log"
	"os"
	"testing"

	"github.com/hashicorp/go-multierror"
	"github.com/jen20/riviera/azure"
)

const TestEnvVar = "RIVIERA_TEST"

type TestCase struct {
	Steps []Step
	State AzureStateBag
}

func Test(t *testing.T, c TestCase) {
	// We only run acceptance tests if an env var is set because they're
	// slow and generally require some outside configuration.
	if os.Getenv(TestEnvVar) == "" {
		t.Skip(fmt.Sprintf(
			"Acceptance tests skipped unless env '%s' set",
			TestEnvVar))
		return
	}

	// We require verbose mode so that the user knows what is going on.
	if !testing.Verbose() {
		t.Fatal("Acceptance tests must be run with the -v flag on tests")
		return
	}

	creds := &azure.AzureResourceManagerCredentials{
		ClientID:       os.Getenv("ARM_CLIENT_ID"),
		ClientSecret:   os.Getenv("ARM_CLIENT_SECRET"),
		TenantID:       os.Getenv("ARM_TENANT_ID"),
		SubscriptionID: os.Getenv("ARM_SUBSCRIPTION_ID"),
	}

	var prerollErrors *multierror.Error
	if creds.ClientID == "" {
		prerollErrors = multierror.Append(prerollErrors, fmt.Errorf("The ARM_CLIENT_ID environment variable must be set to run acceptance tests"))
	}
	if creds.ClientSecret == "" {
		prerollErrors = multierror.Append(prerollErrors, fmt.Errorf("The ARM_CLIENT_SECRET environment variable must be set to run acceptance tests"))
	}
	if creds.TenantID == "" {
		prerollErrors = multierror.Append(prerollErrors, fmt.Errorf("The ARM_TENANT_ID environment variable must be set to run acceptance tests"))
	}
	if creds.SubscriptionID == "" {
		prerollErrors = multierror.Append(prerollErrors, fmt.Errorf("The ARM_SUBSCRIPTION_ID environment variable must be set to run acceptance tests"))
	}
	if errs := prerollErrors.ErrorOrNil(); errs != nil {
		t.Fatal(errs)
	}

	log.Println("[INFO] Creating Azure Client...")
	azureClient, err := azure.NewClient(creds)
	if err != nil {
		t.Fatalf("Error creating Azure Client: %s", err)
	}

	state := &basicAzureStateBag{
		AzureClient: azureClient,
	}

	runner := &basicRunner{
		Steps: c.Steps,
	}

	runner.Run(state)

	if errs := state.ErrorsOrNil(); errs != nil {
		log.Fatal(fmt.Sprintf("%s\n\nThere may be dangling resources in your Azure account!", errs))
	}
}
