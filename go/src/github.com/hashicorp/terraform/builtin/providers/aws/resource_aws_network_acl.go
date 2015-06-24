package aws

import (
	"bytes"
	"fmt"
	"log"
	"sort"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/terraform/helper/hashcode"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/helper/schema"
)

func resourceAwsNetworkAcl() *schema.Resource {

	return &schema.Resource{
		Create: resourceAwsNetworkAclCreate,
		Read:   resourceAwsNetworkAclRead,
		Delete: resourceAwsNetworkAclDelete,
		Update: resourceAwsNetworkAclUpdate,

		Schema: map[string]*schema.Schema{
			"vpc_id": &schema.Schema{
				Type:     schema.TypeString,
				Required: true,
				ForceNew: true,
				Computed: false,
			},
			"subnet_id": &schema.Schema{
				Type:       schema.TypeString,
				Optional:   true,
				ForceNew:   true,
				Computed:   false,
				Deprecated: "Attribute subnet_id is deprecated on network_acl resources. Use subnet_ids instead",
			},
			"subnet_ids": &schema.Schema{
				Type:          schema.TypeSet,
				Optional:      true,
				Computed:      true,
				ConflictsWith: []string{"subnet_id"},
				Elem:          &schema.Schema{Type: schema.TypeString},
				Set:           schema.HashString,
			},
			"ingress": &schema.Schema{
				Type:     schema.TypeSet,
				Required: false,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"from_port": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
						"to_port": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
						"rule_no": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
						"action": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
						"protocol": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
						"cidr_block": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},
						"icmp_type": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
						},
						"icmp_code": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
						},
					},
				},
				Set: resourceAwsNetworkAclEntryHash,
			},
			"egress": &schema.Schema{
				Type:     schema.TypeSet,
				Required: false,
				Optional: true,
				Elem: &schema.Resource{
					Schema: map[string]*schema.Schema{
						"from_port": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
						"to_port": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
						"rule_no": &schema.Schema{
							Type:     schema.TypeInt,
							Required: true,
						},
						"action": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
						"protocol": &schema.Schema{
							Type:     schema.TypeString,
							Required: true,
						},
						"cidr_block": &schema.Schema{
							Type:     schema.TypeString,
							Optional: true,
						},
						"icmp_type": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
						},
						"icmp_code": &schema.Schema{
							Type:     schema.TypeInt,
							Optional: true,
						},
					},
				},
				Set: resourceAwsNetworkAclEntryHash,
			},
			"tags": tagsSchema(),
		},
	}
}

func resourceAwsNetworkAclCreate(d *schema.ResourceData, meta interface{}) error {

	conn := meta.(*AWSClient).ec2conn

	// Create the Network Acl
	createOpts := &ec2.CreateNetworkACLInput{
		VPCID: aws.String(d.Get("vpc_id").(string)),
	}

	log.Printf("[DEBUG] Network Acl create config: %#v", createOpts)
	resp, err := conn.CreateNetworkACL(createOpts)
	if err != nil {
		return fmt.Errorf("Error creating network acl: %s", err)
	}

	// Get the ID and store it
	networkAcl := resp.NetworkACL
	d.SetId(*networkAcl.NetworkACLID)
	log.Printf("[INFO] Network Acl ID: %s", *networkAcl.NetworkACLID)

	// Update rules and subnet association once acl is created
	return resourceAwsNetworkAclUpdate(d, meta)
}

func resourceAwsNetworkAclRead(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	resp, err := conn.DescribeNetworkACLs(&ec2.DescribeNetworkACLsInput{
		NetworkACLIDs: []*string{aws.String(d.Id())},
	})

	if err != nil {
		return err
	}
	if resp == nil {
		return nil
	}

	networkAcl := resp.NetworkACLs[0]
	var ingressEntries []*ec2.NetworkACLEntry
	var egressEntries []*ec2.NetworkACLEntry

	// separate the ingress and egress rules
	for _, e := range networkAcl.Entries {
		// Skip the default rules added by AWS. They can be neither
		// configured or deleted by users.
		if *e.RuleNumber == 32767 {
			continue
		}

		if *e.Egress == true {
			egressEntries = append(egressEntries, e)
		} else {
			ingressEntries = append(ingressEntries, e)
		}
	}

	d.Set("vpc_id", networkAcl.VPCID)
	d.Set("tags", tagsToMap(networkAcl.Tags))

	var s []string
	for _, a := range networkAcl.Associations {
		s = append(s, *a.SubnetID)
	}
	sort.Strings(s)
	if err := d.Set("subnet_ids", s); err != nil {
		return err
	}

	if err := d.Set("ingress", networkAclEntriesToMapList(ingressEntries)); err != nil {
		return err
	}
	if err := d.Set("egress", networkAclEntriesToMapList(egressEntries)); err != nil {
		return err
	}

	return nil
}

func resourceAwsNetworkAclUpdate(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn
	d.Partial(true)

	if d.HasChange("ingress") {
		err := updateNetworkAclEntries(d, "ingress", conn)
		if err != nil {
			return err
		}
	}

	if d.HasChange("egress") {
		err := updateNetworkAclEntries(d, "egress", conn)
		if err != nil {
			return err
		}
	}

	if d.HasChange("subnet_id") {
		//associate new subnet with the acl.
		_, n := d.GetChange("subnet_id")
		newSubnet := n.(string)
		association, err := findNetworkAclAssociation(newSubnet, conn)
		if err != nil {
			return fmt.Errorf("Failed to update acl %s with subnet %s: %s", d.Id(), newSubnet, err)
		}
		_, err = conn.ReplaceNetworkACLAssociation(&ec2.ReplaceNetworkACLAssociationInput{
			AssociationID: association.NetworkACLAssociationID,
			NetworkACLID:  aws.String(d.Id()),
		})
		if err != nil {
			return err
		}
	}

	if d.HasChange("subnet_ids") {
		o, n := d.GetChange("subnet_ids")
		if o == nil {
			o = new(schema.Set)
		}
		if n == nil {
			n = new(schema.Set)
		}

		os := o.(*schema.Set)
		ns := n.(*schema.Set)

		remove := os.Difference(ns).List()
		add := ns.Difference(os).List()

		if len(remove) > 0 {
			// A Network ACL is required for each subnet. In order to disassociate a
			// subnet from this ACL, we must associate it with the default ACL.
			defaultAcl, err := getDefaultNetworkAcl(d.Get("vpc_id").(string), conn)
			if err != nil {
				return fmt.Errorf("Failed to find Default ACL for VPC %s", d.Get("vpc_id").(string))
			}
			for _, r := range remove {
				association, err := findNetworkAclAssociation(r.(string), conn)
				if err != nil {
					return fmt.Errorf("Failed to find acl association: acl %s with subnet %s: %s", d.Id(), r, err)
				}
				_, err = conn.ReplaceNetworkACLAssociation(&ec2.ReplaceNetworkACLAssociationInput{
					AssociationID: association.NetworkACLAssociationID,
					NetworkACLID:  defaultAcl.NetworkACLID,
				})
				if err != nil {
					return err
				}
			}
		}

		if len(add) > 0 {
			for _, a := range add {
				association, err := findNetworkAclAssociation(a.(string), conn)
				if err != nil {
					return fmt.Errorf("Failed to find acl association: acl %s with subnet %s: %s", d.Id(), a, err)
				}
				_, err = conn.ReplaceNetworkACLAssociation(&ec2.ReplaceNetworkACLAssociationInput{
					AssociationID: association.NetworkACLAssociationID,
					NetworkACLID:  aws.String(d.Id()),
				})
				if err != nil {
					return err
				}
			}
		}

	}

	if err := setTags(conn, d); err != nil {
		return err
	} else {
		d.SetPartial("tags")
	}

	d.Partial(false)
	return resourceAwsNetworkAclRead(d, meta)
}

func updateNetworkAclEntries(d *schema.ResourceData, entryType string, conn *ec2.EC2) error {

	o, n := d.GetChange(entryType)

	if o == nil {
		o = new(schema.Set)
	}
	if n == nil {
		n = new(schema.Set)
	}

	os := o.(*schema.Set)
	ns := n.(*schema.Set)

	toBeDeleted, err := expandNetworkAclEntries(os.Difference(ns).List(), entryType)
	if err != nil {
		return err
	}
	for _, remove := range toBeDeleted {

		// AWS includes default rules with all network ACLs that can be
		// neither modified nor destroyed. They have a custom rule
		// number that is out of bounds for any other rule. If we
		// encounter it, just continue. There's no work to be done.
		if *remove.RuleNumber == 32767 {
			continue
		}

		// Delete old Acl
		_, err := conn.DeleteNetworkACLEntry(&ec2.DeleteNetworkACLEntryInput{
			NetworkACLID: aws.String(d.Id()),
			RuleNumber:   remove.RuleNumber,
			Egress:       remove.Egress,
		})
		if err != nil {
			return fmt.Errorf("Error deleting %s entry: %s", entryType, err)
		}
	}

	toBeCreated, err := expandNetworkAclEntries(ns.Difference(os).List(), entryType)
	if err != nil {
		return err
	}
	for _, add := range toBeCreated {
		// Protocol -1 rules don't store ports in AWS. Thus, they'll always
		// hash differently when being read out of the API. Force the user
		// to set from_port and to_port to 0 for these rules, to keep the
		// hashing consistent.
		if *add.Protocol == "-1" {
			to := *add.PortRange.To
			from := *add.PortRange.From
			expected := &expectedPortPair{
				to_port:   0,
				from_port: 0,
			}
			if ok := validatePorts(to, from, *expected); !ok {
				return fmt.Errorf(
					"to_port (%d) and from_port (%d) must both be 0 to use the the 'all' \"-1\" protocol!",
					to, from)
			}
		}

		// AWS mutates the CIDR block into a network implied by the IP and
		// mask provided. This results in hashing inconsistencies between
		// the local config file and the state returned by the API. Error
		// if the user provides a CIDR block with an inappropriate mask
		if err := validateCIDRBlock(*add.CIDRBlock); err != nil {
			return err
		}

		// Add new Acl entry
		_, connErr := conn.CreateNetworkACLEntry(&ec2.CreateNetworkACLEntryInput{
			NetworkACLID: aws.String(d.Id()),
			CIDRBlock:    add.CIDRBlock,
			Egress:       add.Egress,
			PortRange:    add.PortRange,
			Protocol:     add.Protocol,
			RuleAction:   add.RuleAction,
			RuleNumber:   add.RuleNumber,
			ICMPTypeCode: add.ICMPTypeCode,
		})
		if connErr != nil {
			return fmt.Errorf("Error creating %s entry: %s", entryType, connErr)
		}
	}
	return nil
}

func resourceAwsNetworkAclDelete(d *schema.ResourceData, meta interface{}) error {
	conn := meta.(*AWSClient).ec2conn

	log.Printf("[INFO] Deleting Network Acl: %s", d.Id())
	return resource.Retry(5*time.Minute, func() error {
		_, err := conn.DeleteNetworkACL(&ec2.DeleteNetworkACLInput{
			NetworkACLID: aws.String(d.Id()),
		})
		if err != nil {
			ec2err := err.(awserr.Error)
			switch ec2err.Code() {
			case "InvalidNetworkAclID.NotFound":
				return nil
			case "DependencyViolation":
				// In case of dependency violation, we remove the association between subnet and network acl.
				// This means the subnet is attached to default acl of vpc.
				var associations []*ec2.NetworkACLAssociation
				if v, ok := d.GetOk("subnet_id"); ok {

					a, err := findNetworkAclAssociation(v.(string), conn)
					if err != nil {
						return resource.RetryError{Err: fmt.Errorf("Dependency violation: Cannot find ACL %s: %s", d.Id(), err)}
					}
					associations = append(associations, a)
				} else if v, ok := d.GetOk("subnet_ids"); ok {
					ids := v.(*schema.Set).List()
					for _, i := range ids {
						a, err := findNetworkAclAssociation(i.(string), conn)
						if err != nil {
							return resource.RetryError{Err: fmt.Errorf("Dependency violation: Cannot delete acl %s: %s", d.Id(), err)}
						}
						associations = append(associations, a)
					}
				}
				defaultAcl, err := getDefaultNetworkAcl(d.Get("vpc_id").(string), conn)
				if err != nil {
					return resource.RetryError{Err: fmt.Errorf("Dependency violation: Cannot delete acl %s: %s", d.Id(), err)}
				}

				for _, a := range associations {
					_, err = conn.ReplaceNetworkACLAssociation(&ec2.ReplaceNetworkACLAssociationInput{
						AssociationID: a.NetworkACLAssociationID,
						NetworkACLID:  defaultAcl.NetworkACLID,
					})
				}
				return resource.RetryError{Err: err}
			default:
				// Any other error, we want to quit the retry loop immediately
				return resource.RetryError{Err: err}
			}
		}
		log.Printf("[Info] Deleted network ACL %s successfully", d.Id())
		return nil
	})
}

func resourceAwsNetworkAclEntryHash(v interface{}) int {
	var buf bytes.Buffer
	m := v.(map[string]interface{})
	buf.WriteString(fmt.Sprintf("%d-", m["from_port"].(int)))
	buf.WriteString(fmt.Sprintf("%d-", m["to_port"].(int)))
	buf.WriteString(fmt.Sprintf("%d-", m["rule_no"].(int)))
	buf.WriteString(fmt.Sprintf("%s-", m["action"].(string)))

	// The AWS network ACL API only speaks protocol numbers, and that's
	// all we store. Never hash a protocol name.
	protocol := m["protocol"].(string)
	if _, err := strconv.Atoi(m["protocol"].(string)); err != nil {
		// We're a protocol name. Look up the number.
		buf.WriteString(fmt.Sprintf("%d-", protocolIntegers()[protocol]))
	} else {
		// We're a protocol number. Pass the value through.
		buf.WriteString(fmt.Sprintf("%s-", protocol))
	}

	buf.WriteString(fmt.Sprintf("%s-", m["cidr_block"].(string)))

	if v, ok := m["ssl_certificate_id"]; ok {
		buf.WriteString(fmt.Sprintf("%s-", v.(string)))
	}

	if v, ok := m["icmp_type"]; ok {
		buf.WriteString(fmt.Sprintf("%d-", v.(int)))
	}
	if v, ok := m["icmp_code"]; ok {
		buf.WriteString(fmt.Sprintf("%d-", v.(int)))
	}

	return hashcode.String(buf.String())
}

func getDefaultNetworkAcl(vpc_id string, conn *ec2.EC2) (defaultAcl *ec2.NetworkACL, err error) {
	resp, err := conn.DescribeNetworkACLs(&ec2.DescribeNetworkACLsInput{
		Filters: []*ec2.Filter{
			&ec2.Filter{
				Name:   aws.String("default"),
				Values: []*string{aws.String("true")},
			},
			&ec2.Filter{
				Name:   aws.String("vpc-id"),
				Values: []*string{aws.String(vpc_id)},
			},
		},
	})

	if err != nil {
		return nil, err
	}
	return resp.NetworkACLs[0], nil
}

func findNetworkAclAssociation(subnetId string, conn *ec2.EC2) (networkAclAssociation *ec2.NetworkACLAssociation, err error) {
	resp, err := conn.DescribeNetworkACLs(&ec2.DescribeNetworkACLsInput{
		Filters: []*ec2.Filter{
			&ec2.Filter{
				Name:   aws.String("association.subnet-id"),
				Values: []*string{aws.String(subnetId)},
			},
		},
	})

	if err != nil {
		return nil, err
	}
	if resp.NetworkACLs != nil && len(resp.NetworkACLs) > 0 {
		for _, association := range resp.NetworkACLs[0].Associations {
			if *association.SubnetID == subnetId {
				return association, nil
			}
		}
	}
	return nil, fmt.Errorf("could not find association for subnet: %s ", subnetId)
}

// networkAclEntriesToMapList turns ingress/egress rules read from AWS into a list
// of maps.
func networkAclEntriesToMapList(networkAcls []*ec2.NetworkACLEntry) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, len(networkAcls))
	for _, entry := range networkAcls {
		acl := make(map[string]interface{})
		acl["rule_no"] = *entry.RuleNumber
		acl["action"] = *entry.RuleAction
		acl["cidr_block"] = *entry.CIDRBlock

		// The AWS network ACL API only speaks protocol numbers, and
		// that's all we record.
		if _, err := strconv.Atoi(*entry.Protocol); err != nil {
			// We're a protocol name. Look up the number.
			acl["protocol"] = protocolIntegers()[*entry.Protocol]
		} else {
			// We're a protocol number. Pass through.
			acl["protocol"] = *entry.Protocol
		}

		acl["protocol"] = *entry.Protocol
		if entry.PortRange != nil {
			acl["from_port"] = *entry.PortRange.From
			acl["to_port"] = *entry.PortRange.To
		}

		if entry.ICMPTypeCode != nil {
			acl["icmp_type"] = *entry.ICMPTypeCode.Type
			acl["icmp_code"] = *entry.ICMPTypeCode.Code
		}

		result = append(result, acl)
	}

	return result
}
