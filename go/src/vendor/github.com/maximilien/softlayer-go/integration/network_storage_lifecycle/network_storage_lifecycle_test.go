package virtual_guest_lifecycle_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/maximilien/softlayer-go/softlayer"
	testhelpers "github.com/maximilien/softlayer-go/test_helpers"
)

var _ = Describe("SoftLayer Virtual Guest Lifecycle", func() {
	var (
		err                   error
		networkStorageService softlayer.SoftLayer_Network_Storage_Service
	)

	BeforeEach(func() {
		networkStorageService, err = testhelpers.CreateNetworkStorageService()
		Expect(err).ToNot(HaveOccurred())
	})

	Context("SoftLayer_NetworkStorage#CreateNetworkStorage and SoftLayer_SecuritySshKey#DeleteObject", func() {
		It("creates the iSCSI volume and verify it is present and then deletes it", func() {
			disk, err := networkStorageService.CreateNetworkStorage(20, 200, "358694", false)
			Expect(err).ToNot(HaveOccurred())
			Expect(disk.Id).NotTo(Equal(0))

			testhelpers.DeleteDisk(disk.Id)
			Expect(err).ToNot(HaveOccurred())
		})
	})
})
