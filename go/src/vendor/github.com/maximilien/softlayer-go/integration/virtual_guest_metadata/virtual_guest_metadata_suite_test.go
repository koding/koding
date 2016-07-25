package virtual_guest_lifecycle_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	testhelpers "github.com/maximilien/softlayer-go/test_helpers"
)

func TestServices(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Integration: Network Storage Lifecycle Suite")
}

func cleanUpTestResources() {
	virtualGuestIds, err := testhelpers.FindAndDeleteTestVirtualGuests()
	Expect(err).ToNot(HaveOccurred())

	for _, vgId := range virtualGuestIds {
		testhelpers.WaitForVirtualGuestToHaveNoActiveTransactions(vgId)
	}

	err = testhelpers.FindAndDeleteTestSshKeys()
	Expect(err).ToNot(HaveOccurred())
}
