package aws

import (
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/terraform/helper/schema"
)

func dataSourceAwsEbsSnapshot() *schema.Resource {
	return &schema.Resource{
		Read: dataSourceAwsEbsSnapshotRead,

		Schema: map[string]*schema.Schema{
			//selection criteria
			"filter": dataSourceFiltersSchema(),
			"most_recent": {
				Type:     schema.TypeBool,
				Optional: true,
				Default:  false,
				ForceNew: true,
			},
			"owners": {
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
			},
			"snapshot_ids": {
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
			},
			"restorable_by_user_ids": {
				Type:     schema.TypeList,
				Optional: true,
				ForceNew: true,
				Elem:     &schema.Schema{Type: schema.TypeString},
			},
			//Computed values returned
			"snapshot_id": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"volume_id": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"state": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"owner_id": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"owner_alias": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"encrypted": {
				Type:     schema.TypeBool,
				Computed: true,
			},
			"description": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"volume_size": {
				Type:     schema.TypeInt,
				Computed: true,
			},
			"kms_key_id": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"data_encryption_key_id": {
				Type:     schema.TypeString,
				Computed: true,
			},
			"tags": dataSourceTagsSchema(),
		},
	}
}

func dataSourceAwsEbsSnapshotRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	restorableUsers, restorableUsersOk := d.GetOk("restorable_by_user_ids")
	filters, filtersOk := d.GetOk("filter")
	snapshotIds, snapshotIdsOk := d.GetOk("snapshot_ids")
	owners, ownersOk := d.GetOk("owners")

	if !restorableUsersOk && !filtersOk && !snapshotIdsOk && !ownersOk {
		return fmt.Errorf("One of snapshot_ids, filters, restorable_by_user_ids, or owners must be assigned")
	}

	params := &ec2.DescribeSnapshotsInput{}
	if restorableUsersOk {
		params.RestorableByUserIds = expandStringList(restorableUsers.([]interface{}))
	}
	if filtersOk {
		params.Filters = buildAwsDataSourceFilters(filters.(*schema.Set))
	}
	if ownersOk {
		params.OwnerIds = expandStringList(owners.([]interface{}))
	}
	if snapshotIdsOk {
		params.SnapshotIds = expandStringList(snapshotIds.([]interface{}))
	}

	resp, err := conn.DescribeSnapshots(params)
	if err != nil {
		return err
	}

	var snapshot *ec2.Snapshot
	if len(resp.Snapshots) < 1 {
		return fmt.Errorf("Your query returned no results. Please change your search criteria and try again.")
	}

	if len(resp.Snapshots) > 1 {
		recent := d.Get("most_recent").(bool)
		log.Printf("[DEBUG] aws_ebs_snapshot - multiple results found and `most_recent` is set to: %t", recent)
		if recent {
			snapshot = mostRecentSnapshot(resp.Snapshots)
		} else {
			return fmt.Errorf("Your query returned more than one result. Please try a more specific search criteria.")
		}
	} else {
		snapshot = resp.Snapshots[0]
	}

	//Single Snapshot found so set to state
	return snapshotDescriptionAttributes(d, snapshot)
}

func mostRecentSnapshot(snapshots []*ec2.Snapshot) *ec2.Snapshot {
	return sortSnapshots(snapshots)[0]
}

func snapshotDescriptionAttributes(d *schema.ResourceData, snapshot *ec2.Snapshot) error {
	d.SetId(*snapshot.SnapshotId)
	d.Set("snapshot_id", snapshot.SnapshotId)
	d.Set("volume_id", snapshot.VolumeId)
	d.Set("data_encryption_key_id", snapshot.DataEncryptionKeyId)
	d.Set("description", snapshot.Description)
	d.Set("encrypted", snapshot.Encrypted)
	d.Set("kms_key_id", snapshot.KmsKeyId)
	d.Set("volume_size", snapshot.VolumeSize)
	d.Set("state", snapshot.State)
	d.Set("owner_id", snapshot.OwnerId)
	d.Set("owner_alias", snapshot.OwnerAlias)

	if err := d.Set("tags", dataSourceTags(snapshot.Tags)); err != nil {
		return err
	}

	return nil
}
