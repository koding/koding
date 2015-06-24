package openstack

import (
	"fmt"
	"os"
	"testing"

	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"

	"github.com/rackspace/gophercloud/openstack/blockstorage/v1/volumes"
	"github.com/rackspace/gophercloud/openstack/compute/v2/extensions/floatingip"
	"github.com/rackspace/gophercloud/openstack/compute/v2/extensions/volumeattach"
	"github.com/rackspace/gophercloud/openstack/compute/v2/servers"
	"github.com/rackspace/gophercloud/pagination"
)

func TestAccComputeV2Instance_basic(t *testing.T) {
	var instance servers.Server
	var testAccComputeV2Instance_basic = fmt.Sprintf(`
		resource "openstack_compute_instance_v2" "foo" {
			name = "terraform-test"
			security_groups = ["default"]
			network {
				uuid = "%s"
			}
			metadata {
				foo = "bar"
			}
		}`,
		os.Getenv("OS_NETWORK_ID"))

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckComputeV2InstanceDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccComputeV2Instance_basic,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckComputeV2InstanceExists(t, "openstack_compute_instance_v2.foo", &instance),
					testAccCheckComputeV2InstanceMetadata(&instance, "foo", "bar"),
				),
			},
		},
	})
}

func TestAccComputeV2Instance_volumeAttach(t *testing.T) {
	var instance servers.Server
	var volume volumes.Volume

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckComputeV2InstanceDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccComputeV2Instance_volumeAttach,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckBlockStorageV1VolumeExists(t, "openstack_blockstorage_volume_v1.myvol", &volume),
					testAccCheckComputeV2InstanceExists(t, "openstack_compute_instance_v2.foo", &instance),
					testAccCheckComputeV2InstanceVolumeAttachment(&instance, &volume),
				),
			},
		},
	})
}

func TestAccComputeV2Instance_floatingIPAttach(t *testing.T) {
	var instance servers.Server
	var fip floatingip.FloatingIP
	var testAccComputeV2Instance_floatingIPAttach = fmt.Sprintf(`
		resource "openstack_compute_floatingip_v2" "myip" {
		}

		resource "openstack_compute_instance_v2" "foo" {
			name = "terraform-test"
			security_groups = ["default"]
			floating_ip = "${openstack_compute_floatingip_v2.myip.address}"

			network {
				uuid = "%s"
			}
		}`,
		os.Getenv("OS_NETWORK_ID"))

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckComputeV2InstanceDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccComputeV2Instance_floatingIPAttach,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckComputeV2FloatingIPExists(t, "openstack_compute_floatingip_v2.myip", &fip),
					testAccCheckComputeV2InstanceExists(t, "openstack_compute_instance_v2.foo", &instance),
					testAccCheckComputeV2InstanceFloatingIPAttach(&instance, &fip),
				),
			},
		},
	})
}

func testAccCheckComputeV2InstanceDestroy(s *terraform.State) error {
	config := testAccProvider.Meta().(*Config)
	computeClient, err := config.computeV2Client(OS_REGION_NAME)
	if err != nil {
		return fmt.Errorf("(testAccCheckComputeV2InstanceDestroy) Error creating OpenStack compute client: %s", err)
	}

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "openstack_compute_instance_v2" {
			continue
		}

		_, err := servers.Get(computeClient, rs.Primary.ID).Extract()
		if err == nil {
			return fmt.Errorf("Instance still exists")
		}
	}

	return nil
}

func testAccCheckComputeV2InstanceExists(t *testing.T, n string, instance *servers.Server) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No ID is set")
		}

		config := testAccProvider.Meta().(*Config)
		computeClient, err := config.computeV2Client(OS_REGION_NAME)
		if err != nil {
			return fmt.Errorf("(testAccCheckComputeV2InstanceExists) Error creating OpenStack compute client: %s", err)
		}

		found, err := servers.Get(computeClient, rs.Primary.ID).Extract()
		if err != nil {
			return err
		}

		if found.ID != rs.Primary.ID {
			return fmt.Errorf("Instance not found")
		}

		*instance = *found

		return nil
	}
}

func testAccCheckComputeV2InstanceMetadata(
	instance *servers.Server, k string, v string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		if instance.Metadata == nil {
			return fmt.Errorf("No metadata")
		}

		for key, value := range instance.Metadata {
			if k != key {
				continue
			}

			if v == value.(string) {
				return nil
			}

			return fmt.Errorf("Bad value for %s: %s", k, value)
		}

		return fmt.Errorf("Metadata not found: %s", k)
	}
}

func testAccCheckComputeV2InstanceVolumeAttachment(
	instance *servers.Server, volume *volumes.Volume) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		var attachments []volumeattach.VolumeAttachment

		config := testAccProvider.Meta().(*Config)
		computeClient, err := config.computeV2Client(OS_REGION_NAME)
		if err != nil {
			return err
		}
		err = volumeattach.List(computeClient, instance.ID).EachPage(func(page pagination.Page) (bool, error) {
			actual, err := volumeattach.ExtractVolumeAttachments(page)
			if err != nil {
				return false, fmt.Errorf("Unable to lookup attachment: %s", err)
			}

			attachments = actual
			return true, nil
		})

		for _, attachment := range attachments {
			if attachment.VolumeID == volume.ID {
				return nil
			}
		}

		return fmt.Errorf("Volume not found: %s", volume.ID)
	}
}

func testAccCheckComputeV2InstanceFloatingIPAttach(
	instance *servers.Server, fip *floatingip.FloatingIP) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		if fip.InstanceID == instance.ID {
			return nil
		}

		return fmt.Errorf("Floating IP %s was not attached to instance %s", fip.ID, instance.ID)

	}
}

var testAccComputeV2Instance_volumeAttach = fmt.Sprintf(`
  resource "openstack_blockstorage_volume_v1" "myvol" {
    name = "myvol"
    size = 1
  }

  resource "openstack_compute_instance_v2" "foo" {
    region = "%s"
    name = "terraform-test"
    security_groups = ["default"]
    volume {
      volume_id = "${openstack_blockstorage_volume_v1.myvol.id}"
    }
  }`,
	OS_REGION_NAME)
