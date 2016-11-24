package services_test

import (
	"os"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	slclientfakes "github.com/maximilien/softlayer-go/client/fakes"
	datatypes "github.com/maximilien/softlayer-go/data_types"
	softlayer "github.com/maximilien/softlayer-go/softlayer"
	testhelpers "github.com/maximilien/softlayer-go/test_helpers"
)

var _ = Describe("SoftLayer_Hardware", func() {
	var (
		username, apiKey string

		fakeClient *slclientfakes.FakeSoftLayerClient

		hardwareService softlayer.SoftLayer_Hardware_Service
		volume          datatypes.SoftLayer_Network_Storage
		err             error
	)

	BeforeEach(func() {
		username = os.Getenv("SL_USERNAME")
		Expect(username).ToNot(Equal(""))

		apiKey = os.Getenv("SL_API_KEY")
		Expect(apiKey).ToNot(Equal(""))

		fakeClient = slclientfakes.NewFakeSoftLayerClient(username, apiKey)
		Expect(fakeClient).ToNot(BeNil())

		hardwareService, err = fakeClient.GetSoftLayer_Hardware_Service()
		Expect(err).ToNot(HaveOccurred())
		Expect(hardwareService).ToNot(BeNil())

		volume = datatypes.SoftLayer_Network_Storage{}
	})

	Context("#GetName", func() {
		It("returns the name for the service", func() {
			name := hardwareService.GetName()
			Expect(name).To(Equal("SoftLayer_Hardware"))
		})
	})

	Context("#CreateObject", func() {
		var template datatypes.SoftLayer_Hardware_Template

		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Hardware_Service_createObject.json")
			Expect(err).ToNot(HaveOccurred())

			template = datatypes.SoftLayer_Hardware_Template{
				Hostname:                     "softlayer",
				Domain:                       "testing.com",
				ProcessorCoreAmount:          2,
				MemoryCapacity:               2,
				HourlyBillingFlag:            true,
				OperatingSystemReferenceCode: "UBUNTU_LATEST",
				Datacenter: &datatypes.Datacenter{
					Name: "ams01",
				},
			}
		})

		It("creates a new SoftLayer_Hardware instance", func() {
			hardware, err := hardwareService.CreateObject(template)
			Expect(err).ToNot(HaveOccurred())
			Expect(hardware.Id).To(Equal(123456))
			Expect(hardware.Hostname).To(Equal("fake.hostname"))
			Expect(hardware.Domain).To(Equal("fake.domain.com"))
			Expect(hardware.BareMetalInstanceFlag).To(Equal(0))
			Expect(hardware.GlobalIdentifier).To(Equal("abcdefg"))
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.CreateObject(template)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.CreateObject(template)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#GetObject", func() {
		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Hardware_Service_createObject.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("sucessfully retrieves SoftLayer_Virtual_Guest instance", func() {
			hardware, err := hardwareService.GetObject(123456)
			Expect(err).ToNot(HaveOccurred())
			Expect(hardware.Id).To(Equal(123456))
			Expect(hardware.Hostname).To(Equal("fake.hostname"))
			Expect(hardware.Domain).To(Equal("fake.domain.com"))
			Expect(hardware.BareMetalInstanceFlag).To(Equal(0))
			Expect(hardware.GlobalIdentifier).To(Equal("abcdefg"))
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetObject(123456)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetObject(123456)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#AllowAccessToNetworkStorage", func() {
		It("successfully allow access to NetworkStorage instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")
			allowed, err := hardwareService.AllowAccessToNetworkStorage(1234567, volume)
			Expect(err).ToNot(HaveOccurred())
			Expect(allowed).To(BeTrue())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("fasle")

					_, err := hardwareService.AllowAccessToNetworkStorage(1234567, volume)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.AllowAccessToNetworkStorage(1234567, volume)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#FindByIpAddress", func() {
		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Hardware_Service_createObject.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("sucessfully retrieves SoftLayer_Hardware instance", func() {
			hardware, err := hardwareService.FindByIpAddress("169.50.71.69")
			Expect(err).ToNot(HaveOccurred())
			Expect(hardware.BareMetalInstanceFlag).To(Equal(0))
			Expect(hardware.Domain).To(Equal("fake.domain.com"))
			Expect(hardware.Hostname).To(Equal("fake.hostname"))
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					_, err := hardwareService.FindByIpAddress("169.50.71.69")
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					_, err := hardwareService.FindByIpAddress("169.50.71.69")
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#GetAttachedNetworkStorages", func() {
		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Hardware_Service_getAttachedNetworkStorages.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("sucessfully retrieves SoftLayer_Network_Storage attached to this device", func() {
			storage, err := hardwareService.GetAttachedNetworkStorages(1234567, "iscsi")
			Expect(err).ToNot(HaveOccurred())
			Expect(len(storage)).To(Equal(1))
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetAttachedNetworkStorages(1234567, "iscsi")
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetAttachedNetworkStorages(1234567, "iscsi")
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#GetAllowedHost", func() {
		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Hardware_Service_getAllowedHost.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("sucessfully retrieves SoftLayer_Network_Storage_Allowed_Host", func() {
			_, err := hardwareService.GetAllowedHost(1234567)
			Expect(err).ToNot(HaveOccurred())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetAllowedHost(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetAllowedHost(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#GetDatacenter", func() {
		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Hardware_Service_getDatacenter.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("sucessfully retrieves SoftLayer_Location", func() {
			_, err := hardwareService.GetDatacenter(1234567)
			Expect(err).ToNot(HaveOccurred())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetDatacenter(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetDatacenter(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#GetPrimaryIpAddress", func() {
		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("159.99.99.99")
			Expect(err).ToNot(HaveOccurred())
		})

		It("sucessfully retrieves Primary IP Address", func() {
			hdPrimaryIpAddress, err := hardwareService.GetPrimaryIpAddress(1234567)
			Expect(err).ToNot(HaveOccurred())
			Expect(hdPrimaryIpAddress).To(Equal("159.99.99.99"))
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetPrimaryIpAddress(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					_, err := hardwareService.GetPrimaryIpAddress(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#PowerOff", func() {
		It("sucessfully power off hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

			rebooted, err := hardwareService.PowerOff(1234567)
			Expect(err).ToNot(HaveOccurred())
			Expect(rebooted).To(BeTrue())
		})

		It("fails to power off hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

			rebooted, err := hardwareService.PowerOff(1234567)
			Expect(err).To(HaveOccurred())
			Expect(rebooted).To(BeFalse())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.PowerOff(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.PowerOff(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#PowerOffSoft", func() {
		It("sucessfully power off soft hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

			rebooted, err := hardwareService.PowerOffSoft(1234567)
			Expect(err).ToNot(HaveOccurred())
			Expect(rebooted).To(BeTrue())
		})

		It("fails to power off soft hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

			rebooted, err := hardwareService.PowerOffSoft(1234567)
			Expect(err).To(HaveOccurred())
			Expect(rebooted).To(BeFalse())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

					_, err := hardwareService.PowerOffSoft(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

					_, err := hardwareService.PowerOffSoft(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#PowerOn", func() {
		It("sucessfully power on hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

			rebooted, err := hardwareService.PowerOn(1234567)
			Expect(err).ToNot(HaveOccurred())
			Expect(rebooted).To(BeTrue())
		})

		It("fails to power on hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

			rebooted, err := hardwareService.PowerOn(1234567)
			Expect(err).To(HaveOccurred())
			Expect(rebooted).To(BeFalse())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.PowerOn(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.PowerOn(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#RebootDefault", func() {
		It("sucessfully default reboots hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

			rebooted, err := hardwareService.RebootDefault(1234567)
			Expect(err).ToNot(HaveOccurred())
			Expect(rebooted).To(BeTrue())
		})

		It("fails to default reboot hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

			rebooted, err := hardwareService.RebootDefault(1234567)
			Expect(err).To(HaveOccurred())
			Expect(rebooted).To(BeFalse())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

					_, err := hardwareService.RebootDefault(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

					_, err := hardwareService.RebootDefault(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#RebootSoft", func() {
		It("sucessfully soft reboots hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

			rebooted, err := hardwareService.RebootSoft(1234567)
			Expect(err).ToNot(HaveOccurred())
			Expect(rebooted).To(BeTrue())
		})

		It("fails to soft reboot hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

			rebooted, err := hardwareService.RebootSoft(1234567)
			Expect(err).To(HaveOccurred())
			Expect(rebooted).To(BeFalse())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.RebootSoft(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.RebootSoft(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#RebootHard", func() {
		It("sucessfully hard reboot hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("true")

			rebooted, err := hardwareService.RebootHard(1234567)
			Expect(err).ToNot(HaveOccurred())
			Expect(rebooted).To(BeTrue())
		})

		It("fails to hard reboot hardware instance", func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

			rebooted, err := hardwareService.RebootHard(1234567)
			Expect(err).To(HaveOccurred())
			Expect(rebooted).To(BeFalse())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.RebootHard(1234567)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode
					fakeClient.FakeHttpClient.DoRawHttpRequestResponse = []byte("false")

					_, err := hardwareService.RebootHard(1234567)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})

	Context("#SetTags", func() {
		BeforeEach(func() {
			fakeClient.FakeHttpClient.DoRawHttpRequestResponse, err = testhelpers.ReadJsonTestFixtures("services", "SoftLayer_Hardware_Service_setTags.json")
			Expect(err).ToNot(HaveOccurred())
		})

		It("sets tags: tag0, tag1, tag2 to hardware instance", func() {
			tags := []string{"tag0", "tag1", "tag2"}
			tagsWasSet, err := hardwareService.SetTags(1234567, tags)

			Expect(err).ToNot(HaveOccurred())
			Expect(tagsWasSet).To(BeTrue())
		})

		Context("when HTTP client returns error codes 40x or 50x", func() {
			It("fails for error code 40x", func() {
				errorCodes := []int{400, 401, 499}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					tags := []string{"tag0", "tag1", "tag2"}
					_, err := hardwareService.SetTags(1234567, tags)
					Expect(err).To(HaveOccurred())
				}
			})

			It("fails for error code 50x", func() {
				errorCodes := []int{500, 501, 599}
				for _, errorCode := range errorCodes {
					fakeClient.FakeHttpClient.DoRawHttpRequestInt = errorCode

					tags := []string{"tag0", "tag1", "tag2"}
					_, err := hardwareService.SetTags(1234567, tags)
					Expect(err).To(HaveOccurred())
				}
			})
		})
	})
})
