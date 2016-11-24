package test_helpers

import (
	"encoding/json"
	"errors"

	datatypes "github.com/maximilien/softlayer-go/data_types"
	testhelpers "github.com/maximilien/softlayer-go/test_helpers"
)

type FakeProductPackageService struct{}

func (fps *FakeProductPackageService) GetName() string {
	return "Mock_Product_Package_Service"
}

func (fps *FakeProductPackageService) GetItemsByType(packageType string) ([]datatypes.SoftLayer_Product_Item, error) {
	response, _ := testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Product_Package_getItemsByType_virtual_server.json")

	productItems := []datatypes.SoftLayer_Product_Item{}
	json.Unmarshal(response, &productItems)

	return productItems, nil
}

func (fps *FakeProductPackageService) GetItemPrices(packageId int, filters string) ([]datatypes.SoftLayer_Product_Item_Price, error) {
	return []datatypes.SoftLayer_Product_Item_Price{}, errors.New("Not supported")
}

func (fps *FakeProductPackageService) GetItems(packageId int, filters string) ([]datatypes.SoftLayer_Product_Item, error) {
	return []datatypes.SoftLayer_Product_Item{}, errors.New("Not supported")
}

func (fps *FakeProductPackageService) GetPackagesByType(packageType string) ([]datatypes.Softlayer_Product_Package, error) {
	return []datatypes.Softlayer_Product_Package{}, errors.New("Not supported")
}

func (fps *FakeProductPackageService) GetOnePackageByType(packageType string) (datatypes.Softlayer_Product_Package, error) {
	return datatypes.Softlayer_Product_Package{}, errors.New("Not supported")
}
