package aws

import (
	"fmt"
	"net"
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
)

func expandNetworkAclEntries(configured []interface{}, entryType string) ([]*ec2.NetworkACLEntry, error) {
	entries := make([]*ec2.NetworkACLEntry, 0, len(configured))
	for _, eRaw := range configured {
		data := eRaw.(map[string]interface{})
		protocol := data["protocol"].(string)
		p, err := strconv.Atoi(protocol)
		if err != nil {
			var ok bool
			p, ok = protocolIntegers()[protocol]
			if !ok {
				return nil, fmt.Errorf("Invalid Protocol %s for rule %#v", protocol, data)
			}
		}

		e := &ec2.NetworkACLEntry{
			Protocol: aws.String(strconv.Itoa(p)),
			PortRange: &ec2.PortRange{
				From: aws.Long(int64(data["from_port"].(int))),
				To:   aws.Long(int64(data["to_port"].(int))),
			},
			Egress:     aws.Boolean((entryType == "egress")),
			RuleAction: aws.String(data["action"].(string)),
			RuleNumber: aws.Long(int64(data["rule_no"].(int))),
			CIDRBlock:  aws.String(data["cidr_block"].(string)),
		}

		// Specify additional required fields for ICMP
		if p == 1 {
			e.ICMPTypeCode = &ec2.ICMPTypeCode{}
			if v, ok := data["icmp_code"]; ok {
				e.ICMPTypeCode.Code = aws.Long(int64(v.(int)))
			}
			if v, ok := data["icmp_type"]; ok {
				e.ICMPTypeCode.Type = aws.Long(int64(v.(int)))
			}
		}

		entries = append(entries, e)
	}
	return entries, nil
}

func flattenNetworkAclEntries(list []*ec2.NetworkACLEntry) []map[string]interface{} {
	entries := make([]map[string]interface{}, 0, len(list))

	for _, entry := range list {
		entries = append(entries, map[string]interface{}{
			"from_port":  *entry.PortRange.From,
			"to_port":    *entry.PortRange.To,
			"action":     *entry.RuleAction,
			"rule_no":    *entry.RuleNumber,
			"protocol":   *entry.Protocol,
			"cidr_block": *entry.CIDRBlock,
		})
	}

	return entries

}

func protocolIntegers() map[string]int {
	var protocolIntegers = make(map[string]int)
	protocolIntegers = map[string]int{
		"udp":  17,
		"tcp":  6,
		"icmp": 1,
		"all":  -1,
	}
	return protocolIntegers
}

// expectedPortPair stores a pair of ports we expect to see together.
type expectedPortPair struct {
	to_port   int64
	from_port int64
}

// validatePorts ensures the ports and protocol match expected
// values.
func validatePorts(to int64, from int64, expected expectedPortPair) bool {
	if to != expected.to_port || from != expected.from_port {
		return false
	}

	return true
}

// validateCIDRBlock ensures the passed CIDR block represents an implied
// network, and not an overly-specified IP address.
func validateCIDRBlock(cidr string) error {
	_, ipnet, err := net.ParseCIDR(cidr)
	if err != nil {
		return err
	}
	if ipnet.String() != cidr {
		return fmt.Errorf("%s is not a valid mask; did you mean %s?", cidr, ipnet)
	}

	return nil
}
