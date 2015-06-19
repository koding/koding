package azure

import (
	"fmt"
	"os"
	"sync"

	"github.com/Azure/azure-sdk-for-go/management"
	"github.com/Azure/azure-sdk-for-go/management/hostedservice"
	"github.com/Azure/azure-sdk-for-go/management/networksecuritygroup"
	"github.com/Azure/azure-sdk-for-go/management/osimage"
	"github.com/Azure/azure-sdk-for-go/management/storageservice"
	"github.com/Azure/azure-sdk-for-go/management/virtualmachine"
	"github.com/Azure/azure-sdk-for-go/management/virtualmachinedisk"
	"github.com/Azure/azure-sdk-for-go/management/virtualmachineimage"
	"github.com/Azure/azure-sdk-for-go/management/virtualnetwork"
	"github.com/Azure/azure-sdk-for-go/storage"
)

// Config is the configuration structure used to instantiate a
// new Azure management client.
type Config struct {
	SettingsFile   string
	SubscriptionID string
	Certificate    []byte
	ManagementURL  string
}

// Client contains all the handles required for managing Azure services.
type Client struct {
	mgmtClient management.Client

	hostedServiceClient hostedservice.HostedServiceClient

	secGroupClient networksecuritygroup.SecurityGroupClient

	osImageClient osimage.OSImageClient

	storageServiceClient storageservice.StorageServiceClient

	vmClient virtualmachine.VirtualMachineClient

	vmDiskClient virtualmachinedisk.DiskClient

	vmImageClient virtualmachineimage.Client

	// unfortunately; because of how Azure's network API works; doing networking operations
	// concurrently is very hazardous, and we need a mutex to guard the VirtualNetworkClient.
	vnetClient virtualnetwork.VirtualNetworkClient
	mutex      *sync.Mutex
}

// getStorageClientForStorageService is helper method which returns the
// storage.Client associated to the given storage service name.
func (c Client) getStorageClientForStorageService(serviceName string) (storage.Client, error) {
	var storageClient storage.Client

	keys, err := c.storageServiceClient.GetStorageServiceKeys(serviceName)
	if err != nil {
		return storageClient, fmt.Errorf("Failed getting Storage Service keys for %s: %s", serviceName, err)
	}

	storageClient, err = storage.NewBasicClient(serviceName, keys.PrimaryKey)
	if err != nil {
		return storageClient, fmt.Errorf("Failed creating Storage Service client for %s: %s", serviceName, err)
	}

	return storageClient, err
}

// getStorageServiceBlobClient is a helper method which returns the
// storage.BlobStorageClient associated to the given storage service name.
func (c Client) getStorageServiceBlobClient(serviceName string) (storage.BlobStorageClient, error) {
	storageClient, err := c.getStorageClientForStorageService(serviceName)
	if err != nil {
		return storage.BlobStorageClient{}, err
	}

	return storageClient.GetBlobService(), nil
}

// getStorageServiceQueueClient is a helper method which returns the
// storage.QueueServiceClient associated to the given storage service name.
func (c Client) getStorageServiceQueueClient(serviceName string) (storage.QueueServiceClient, error) {
	storageClient, err := c.getStorageClientForStorageService(serviceName)
	if err != nil {
		return storage.QueueServiceClient{}, err
	}

	return storageClient.GetQueueService(), err
}

// NewClientFromSettingsFile returns a new Azure management
// client created using a publish settings file.
func (c *Config) NewClientFromSettingsFile() (*Client, error) {
	if _, err := os.Stat(c.SettingsFile); os.IsNotExist(err) {
		return nil, fmt.Errorf("Publish Settings file %q does not exist!", c.SettingsFile)
	}

	mc, err := management.ClientFromPublishSettingsFile(c.SettingsFile, c.SubscriptionID)
	if err != nil {
		return nil, nil
	}

	return &Client{
		mgmtClient:           mc,
		hostedServiceClient:  hostedservice.NewClient(mc),
		secGroupClient:       networksecuritygroup.NewClient(mc),
		osImageClient:        osimage.NewClient(mc),
		storageServiceClient: storageservice.NewClient(mc),
		vmClient:             virtualmachine.NewClient(mc),
		vmDiskClient:         virtualmachinedisk.NewClient(mc),
		vmImageClient:        virtualmachineimage.NewClient(mc),
		vnetClient:           virtualnetwork.NewClient(mc),
		mutex:                &sync.Mutex{},
	}, nil
}

// NewClient returns a new Azure management client created
// using a subscription ID and certificate.
func (c *Config) NewClient() (*Client, error) {
	mc, err := management.NewClient(c.SubscriptionID, c.Certificate)
	if err != nil {
		return nil, nil
	}

	return &Client{
		mgmtClient:           mc,
		hostedServiceClient:  hostedservice.NewClient(mc),
		secGroupClient:       networksecuritygroup.NewClient(mc),
		osImageClient:        osimage.NewClient(mc),
		storageServiceClient: storageservice.NewClient(mc),
		vmClient:             virtualmachine.NewClient(mc),
		vmDiskClient:         virtualmachinedisk.NewClient(mc),
		vmImageClient:        virtualmachineimage.NewClient(mc),
		vnetClient:           virtualnetwork.NewClient(mc),
		mutex:                &sync.Mutex{},
	}, nil
}
