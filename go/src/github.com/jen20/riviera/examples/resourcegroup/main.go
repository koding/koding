package main

import (
	"fmt"
	"log"
	"os"

	"github.com/jen20/riviera/azure"
)

const resourceGroupName = "rivieraresourcegroup1"

func main() {
	// 1 - Configure the ARM Client with credentials
	creds := &azure.AzureResourceManagerCredentials{
		ClientID:       os.Getenv("ARM_CLIENT_ID"),
		ClientSecret:   os.Getenv("ARM_CLIENT_SECRET"),
		TenantID:       os.Getenv("ARM_TENANT_ID"),
		SubscriptionID: os.Getenv("ARM_SUBSCRIPTION_ID"),
	}

	azureClient, err := azure.NewClient(creds)
	if err != nil {
		log.Fatal(err)
	}

	// 2 - Create a new request with a location attached
	r := azureClient.NewRequest()

	// 3 - Create a command object, and assign it to the request
	r.Command = azure.CreateResourceGroup{
		Name:     resourceGroupName,
		Location: azure.WestUS,
		Tags: map[string]*string{
			"Key1": azure.String("value1"),
			"Key2": azure.String("value2"),
		},
	}

	// 4 - Execute the command
	response, err := r.Execute()
	if err != nil {
		log.Fatal(err)
	}

	// 5 - Make use of the result
	if response.IsSuccessful() {
		result := response.Parsed.(*azure.CreateResourceGroupResponse)
		fmt.Printf("Created resource group %q:\n", *result.Name)
		fmt.Printf("\tID: %s\n", *result.ID)
		fmt.Printf("\tLocation: %s\n", *result.Location)
		fmt.Printf("\tProvisioningState: %s\n", *result.ProvisioningState)
	} else {
		log.Fatalf("Failed creating resource group: %s", response.Error.Error())
	}

	// 6 - Delete the resource group
	d := azureClient.NewRequest()
	d.Command = azure.DeleteResourceGroup{
		Name: resourceGroupName,
	}
	deleteResponse, err := d.Execute()
	if err != nil {
		log.Fatal(err)
	}
	if deleteResponse.IsSuccessful() {
		log.Printf("Successfully deleted resource group %q", resourceGroupName)
	} else {
		log.Printf("Error deleting resource group %q", resourceGroupName)
	}
}
