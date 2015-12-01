package services_test

import (
	"os"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	slclientfakes "github.com/maximilien/softlayer-go/client/fakes"
	softlayer "github.com/maximilien/softlayer-go/softlayer"
	testhelpers "github.com/maximilien/softlayer-go/test_helpers"
)

var _ = Describe("SoftLayer_Product_Package", func() {
	var (
		username, apiKey string

		fakeClient *slclientfakes.FakeSoftLayerClient

		productPackageService softlayer.SoftLayer_Product_Package_Service
		err                   error
	)

	BeforeEach(func() {
		username = os.Getenv("SL_USERNAME")
		Expect(username).ToNot(Equal(""))

		apiKey = os.Getenv("SL_API_KEY")
		Expect(apiKey).ToNot(Equal(""))

		fakeClient = slclientfakes.NewFakeSoftLayerClient(username, apiKey)
		Expect(fakeClient).ToNot(BeNil())

		productPackageService, err = fakeClient.GetSoftLayer_Product_Package_Service()
		Expect(err).ToNot(HaveOccurred())
		Expect(productPackageService).ToNot(BeNil())
	})

	Context("#GetName", func() {
		It("returns the name for the service", func() {
			name := productPackageService.GetName()
			Expect(name).To(Equal("SoftLayer_Product_Package"))
		})
	})

	Context("#GetItemPrices", func() {
		BeforeEach(func() {
			fakeClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Product_Package_getItemPrices.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("returns an array of datatypes.SoftLayer_Item_Price", func() {
			itemPrices, err := productPackageService.GetItemPrices(0)
			Expect(err).ToNot(HaveOccurred())
			Expect(len(itemPrices)).To(Equal(1))
			Expect(itemPrices[0].Id).To(Equal(123))
			Expect(itemPrices[0].Item.Id).To(Equal(456))
		})
	})

	Context("#GetItemPricesBySize", func() {
		BeforeEach(func() {
			fakeClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Product_Package_getItemPrices.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("returns an array of datatypes.SoftLayer_Item_Price", func() {
			itemPrices, err := productPackageService.GetItemPricesBySize(222, 20)
			Expect(err).ToNot(HaveOccurred())
			Expect(len(itemPrices)).To(Equal(1))
			Expect(itemPrices[0].Id).To(Equal(123))
			Expect(itemPrices[0].Item.Id).To(Equal(456))
		})
	})
})
