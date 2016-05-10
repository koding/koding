package main

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"time"

	"github.com/davecgh/go-spew/spew"
	"github.com/jen20/riviera/azure"
	"github.com/jen20/riviera/storage"
)

func main() {
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

	resourceGroupName, err := createResourceGroup(azureClient)
	if err != nil {
		log.Fatal(err)
	}

	storageAccountName := fmt.Sprintf("rivierastorage%d", rand.Intn(8999)+1000)

	r := azureClient.NewRequest()
	r.Command = storage.CreateStorageAccount{
		ResourceGroupName: resourceGroupName,
		Name:              storageAccountName,
		AccountType:       azure.String("Standard_LRS"),
		Location:          azure.WestUS,
	}

	response, err := r.Execute()
	if err != nil {
		log.Fatal(err)
	}

	if response.IsSuccessful() {
		result := response.Parsed.(*storage.CreateStorageAccountResponse)

		log.Printf("Created Storage Account\n")
		log.Printf("\tLocation: %s\n", *result.Location)
		log.Printf("\tAccount Type: %s\n", *result.AccountType)
	} else {
		log.Printf("Failed creating Storage Account\n")
	}

	read := azureClient.NewRequest()
	read.Command = storage.GetStorageAccountProperties{
		ResourceGroupName: resourceGroupName,
		Name:              storageAccountName,
	}

	readResponse, err := read.Execute()
	if err != nil {
		log.Fatalf("Failed reading account: %s", err)
	}

	var id string
	if readResponse.IsSuccessful() {
		result := readResponse.Parsed.(*storage.GetStorageAccountPropertiesResponse)

		log.Printf("ID: %s\n", *result.ID)
		spew.Dump(result)
		id = *result.ID
	} else {
		log.Printf("Failed getting Storage Account type: %s\n", readResponse.Error.Error())
	}

	r2 := azureClient.NewRequestForURI(id)
	r2.Command = storage.UpdateStorageAccountType{
		AccountType: azure.String("Standard_GRS"),
	}
	response2, err := r2.Execute()
	if err != nil {
		log.Fatal(err)
	}

	if response2.IsSuccessful() {
		result := response2.Parsed.(*storage.UpdateStorageAccountTypeResponse)
		log.Printf("Updated Storage Account Type to %s\n", *result.AccountType)
	} else {
		log.Printf("Failed updating Storage Account type\n")
	}

	r3 := azureClient.NewRequestForURI(id)
	r3.Command = storage.UpdateStorageAccountCustomDomain{
		CustomDomain: storage.CustomDomain{
			Name: azure.String("testname.hashicorptest.com"),
		},
	}

	response3, err := r3.Execute()
	if err != nil {
		log.Fatal(err)
	}

	if response3.IsSuccessful() {
		result := response3.Parsed.(*storage.UpdateStorageAccountCustomDomainResponse)
		log.Printf("Updated Storage Account Custom Domain to %s\n", *result.CustomDomain.Name)
	} else {
		log.Printf("Failed updating Storage Account Custom Domain\n")
	}

}

func init() {
	rand.Seed(time.Now().UTC().UnixNano())
}

func createResourceGroup(azureClient *azure.Client) (string, error) {
	name := fmt.Sprintf("riviera_resource_group_%d", rand.Intn(8999)+1000)

	r := azureClient.NewRequest()
	r.Command = azure.CreateResourceGroup{
		Name:     name,
		Location: azure.WestUS,
	}

	response, err := r.Execute()
	if err != nil {
		return "", err
	}

	if !response.IsSuccessful() {
		return "", fmt.Errorf("Error creating resource group %q", name)
	}

	return name, nil
}
