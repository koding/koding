package client_fakes

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"

	services "github.com/maximilien/softlayer-go/services"
	softlayer "github.com/maximilien/softlayer-go/softlayer"
)

const (
	SOFTLAYER_API_URL  = "api.softlayer.com/rest/v3"
	TEMPLATE_ROOT_PATH = "templates"
)

type FakeSoftLayerClient struct {
	Username string
	ApiKey   string

	TemplatePath string

	SoftLayerServices map[string]softlayer.Service

	FakeHttpClient *FakeHttpClient
}

func NewFakeSoftLayerClient(username, apiKey string) *FakeSoftLayerClient {
	pwd, _ := os.Getwd()
	fslc := &FakeSoftLayerClient{
		Username: username,
		ApiKey:   apiKey,

		TemplatePath: filepath.Join(pwd, TEMPLATE_ROOT_PATH),

		FakeHttpClient: NewFakeHttpClient(username, apiKey),

		SoftLayerServices: map[string]softlayer.Service{},
	}

	fslc.initSoftLayerServices()

	return fslc
}

//softlayer.Client interface methods

func (fslc *FakeSoftLayerClient) GetHttpClient() softlayer.HttpClient {
	return fslc.FakeHttpClient
}

func (fslc *FakeSoftLayerClient) GetService(serviceName string) (softlayer.Service, error) {
	slService, ok := fslc.SoftLayerServices[serviceName]
	if !ok {
		return nil, errors.New(fmt.Sprintf("softlayer-go does not support service '%s'", serviceName))
	}

	return slService, nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Account_Service() (softlayer.SoftLayer_Account_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Account")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Account_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Virtual_Guest_Service() (softlayer.SoftLayer_Virtual_Guest_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Virtual_Guest")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Virtual_Guest_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Dns_Domain_Service() (softlayer.SoftLayer_Dns_Domain_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Dns_Domain")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Dns_Domain_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Virtual_Disk_Image_Service() (softlayer.SoftLayer_Virtual_Disk_Image_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Virtual_Disk_Image")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Virtual_Disk_Image_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Security_Ssh_Key_Service() (softlayer.SoftLayer_Security_Ssh_Key_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Security_Ssh_Key")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Security_Ssh_Key_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Network_Storage_Service() (softlayer.SoftLayer_Network_Storage_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Network_Storage")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Network_Storage_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Network_Storage_Allowed_Host_Service() (softlayer.SoftLayer_Network_Storage_Allowed_Host_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Network_Storage_Allowed_Host")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Network_Storage_Allowed_Host_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Product_Order_Service() (softlayer.SoftLayer_Product_Order_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Product_Order")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Product_Order_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Product_Package_Service() (softlayer.SoftLayer_Product_Package_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Product_Package")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Product_Package_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Billing_Item_Cancellation_Request_Service() (softlayer.SoftLayer_Billing_Item_Cancellation_Request_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Billing_Item_Cancellation_Request")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Billing_Item_Cancellation_Request_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Billing_Item_Service() (softlayer.SoftLayer_Billing_Item_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Billing_Item")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Billing_Item_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Virtual_Guest_Block_Device_Template_Group_Service() (softlayer.SoftLayer_Virtual_Guest_Block_Device_Template_Group_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Virtual_Guest_Block_Device_Template_Group")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Virtual_Guest_Block_Device_Template_Group_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Hardware_Service() (softlayer.SoftLayer_Hardware_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Hardware")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Hardware_Service), nil
}

func (fslc *FakeSoftLayerClient) GetSoftLayer_Dns_Domain_ResourceRecord_Service() (softlayer.SoftLayer_Dns_Domain_ResourceRecord_Service, error) {
	slService, err := fslc.GetService("SoftLayer_Dns_Domain_ResourceRecord")
	if err != nil {
		return nil, err
	}

	return slService.(softlayer.SoftLayer_Dns_Domain_ResourceRecord_Service), nil
}

//Private methods

func (fslc *FakeSoftLayerClient) initSoftLayerServices() {
	fslc.SoftLayerServices["SoftLayer_Account"] = services.NewSoftLayer_Account_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Virtual_Guest"] = services.NewSoftLayer_Virtual_Guest_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Virtual_Disk_Image"] = services.NewSoftLayer_Virtual_Disk_Image_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Security_Ssh_Key"] = services.NewSoftLayer_Security_Ssh_Key_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Network_Storage"] = services.NewSoftLayer_Network_Storage_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Network_Storage_Allowed_Host"] = services.NewSoftLayer_Network_Storage_Allowed_Host_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Product_Order"] = services.NewSoftLayer_Product_Order_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Product_Package"] = services.NewSoftLayer_Product_Package_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Billing_Item_Cancellation_Request"] = services.NewSoftLayer_Billing_Item_Cancellation_Request_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Billing_Item"] = services.NewSoftLayer_Billing_Item_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Virtual_Guest_Block_Device_Template_Group"] = services.NewSoftLayer_Virtual_Guest_Block_Device_Template_Group_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Hardware"] = services.NewSoftLayer_Hardware_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Dns_Domain"] = services.NewSoftLayer_Dns_Domain_Service(fslc)
	fslc.SoftLayerServices["SoftLayer_Dns_Domain_ResourceRecord"] = services.NewSoftLayer_Dns_Domain_ResourceRecord_Service(fslc)
}
