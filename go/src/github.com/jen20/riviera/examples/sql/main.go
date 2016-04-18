package main

import (
	"fmt"
	"log"
	"math/rand"
	"os"

	"github.com/davecgh/go-spew/spew"
	"github.com/jen20/riviera/azure"
	"github.com/jen20/riviera/sql"
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

	r := azureClient.NewRequest()

	r.Command = sql.CreateOrUpdateServer{
		ResourceGroupName: resourceGroupName,
		Name:              "rivieradbservertest123",
		Location:          azure.WestUS,
		Tags: map[string]*string{
			"Key1": azure.String("value1"),
			"Key2": azure.String("value2"),
		},
		AdministratorLogin:         azure.String("hello"),
		AdministratorLoginPassword: azure.String("thisIsDog11'"),
		Version:                    azure.String("12.0"),
	}

	response, err := r.Execute()
	if err != nil {
		log.Fatal(err)
	}

	if response.IsSuccessful() {
		result := response.Parsed.(*sql.CreateOrUpdateServerResponse)

		log.Printf("Created SQL Server %q\n", result.Name)
		log.Printf("\tID: %s\n", *result.ID)
		log.Printf("\tFQDN: %s\n", *result.FullyQualifiedDomainName)
		log.Printf("\tFQDN: %s\n", *result.State)
	} else {
		log.Printf("Failed creating SQL Server: %s", response.Error.Error())
	}

	r3 := azureClient.NewRequest()
	r3.Command = sql.GetServer{
		ResourceGroupName: resourceGroupName,
		Name:              "rivieradbservertest123",
	}
	response, err = r3.Execute()
	if err != nil {
		log.Fatal(err)
	}

	if response.IsSuccessful() {
		result := response.Parsed.(*sql.GetServerResponse)

		log.Printf("Got SQL Server %q\n", result.Name)
		log.Printf(spew.Sdump(result))
	} else {
		log.Printf("Failed to get SQL Server: %s", response.Error.Error())
	}

	r2 := azureClient.NewRequest()
	r2.Command = sql.DeleteServer{
		ResourceGroupName: resourceGroupName,
		Name:              "rivieradbservertest123",
	}

	response2, err := r2.Execute()
	if err != nil {
		log.Fatal(err)
	}

	if response2.IsSuccessful() {
		log.Println("Deleted Server")
	} else {
		log.Printf("Failed deleting SQL Server: %s", response2.Error.Error())
	}

}

func createResourceGroup(azureClient *azure.Client) (string, error) {
	name := fmt.Sprintf("riviera_resource_group_%d", rand.Intn(8999)+1000)

	r := azureClient.NewRequest()

	r.Command = azure.CreateResourceGroup{
		Name:     name,
		Location: azure.WestUS,
		Tags: map[string]*string{
			"Key1": azure.String("value1"),
			"Key2": azure.String("value2"),
		},
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
