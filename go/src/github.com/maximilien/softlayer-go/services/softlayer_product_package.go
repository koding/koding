package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"

	datatypes "github.com/maximilien/softlayer-go/data_types"
	softlayer "github.com/maximilien/softlayer-go/softlayer"
)

type softLayer_Product_Package_Service struct {
	client softlayer.Client
}

func NewSoftLayer_Product_Package_Service(client softlayer.Client) *softLayer_Product_Package_Service {
	return &softLayer_Product_Package_Service{
		client: client,
	}
}

func (slpp *softLayer_Product_Package_Service) GetName() string {
	return "SoftLayer_Product_Package"
}

func (slpp *softLayer_Product_Package_Service) GetItemPrices(packageId int) ([]datatypes.SoftLayer_Item_Price, error) {
	response, err := slpp.client.DoRawHttpRequestWithObjectMask(fmt.Sprintf("%s/%d/getItemPrices.json", slpp.GetName(), packageId), []string{"id", "item.id", "item.description", "item.capacity"}, "GET", new(bytes.Buffer))
	if err != nil {
		return []datatypes.SoftLayer_Item_Price{}, err
	}

	itemPrices := []datatypes.SoftLayer_Item_Price{}
	err = json.Unmarshal(response, &itemPrices)
	if err != nil {
		return []datatypes.SoftLayer_Item_Price{}, err
	}

	return itemPrices, nil
}

func (slpp *softLayer_Product_Package_Service) GetItemPricesBySize(packageId int, size int) ([]datatypes.SoftLayer_Item_Price, error) {
	keyName := strconv.Itoa(size) + "_GB_PERFORMANCE_STORAGE_SPACE"
	filter := string(`{"itemPrices":{"item":{"keyName":{"operation":"` + keyName + `"}}}}`)

	response, err := slpp.client.DoRawHttpRequestWithObjectFilterAndObjectMask(fmt.Sprintf("%s/%d/getItemPrices.json", slpp.GetName(), packageId), []string{"id", "locationGroupId", "item.id", "item.keyName", "item.units", "item.description", "item.capacity"}, fmt.Sprintf(string(filter)), "GET", new(bytes.Buffer))
	if err != nil {
		return []datatypes.SoftLayer_Item_Price{}, err
	}

	itemPrices := []datatypes.SoftLayer_Item_Price{}
	err = json.Unmarshal(response, &itemPrices)
	if err != nil {
		return []datatypes.SoftLayer_Item_Price{}, err
	}

	return itemPrices, nil
}
