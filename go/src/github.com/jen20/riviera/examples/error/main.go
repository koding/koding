package main

import (
	"log"
	"os"

	"github.com/jen20/riviera/azure"
)

// This is invalid as it ends with a "."
const resourceGroupName = "thisisinvalid."

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

	// 2 - Create a new request
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

	if response.IsSuccessful() {
		log.Println("Worked - this shouldn't happen here!")
	} else {
		log.Println("Didn't Work:")
		log.Printf(response.Error.Error())
	}
}
