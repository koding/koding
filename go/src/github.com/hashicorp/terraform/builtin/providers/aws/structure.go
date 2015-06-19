package aws

import (
	"bytes"
	"encoding/json"
	"fmt"
	"sort"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/aws/aws-sdk-go/service/elb"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/aws/aws-sdk-go/service/route53"
	"github.com/hashicorp/terraform/helper/schema"
)

// Takes the result of flatmap.Expand for an array of listeners and
// returns ELB API compatible objects
func expandListeners(configured []interface{}) ([]*elb.Listener, error) {
	listeners := make([]*elb.Listener, 0, len(configured))

	// Loop over our configured listeners and create
	// an array of aws-sdk-go compatabile objects
	for _, lRaw := range configured {
		data := lRaw.(map[string]interface{})

		ip := int64(data["instance_port"].(int))
		lp := int64(data["lb_port"].(int))
		l := &elb.Listener{
			InstancePort:     &ip,
			InstanceProtocol: aws.String(data["instance_protocol"].(string)),
			LoadBalancerPort: &lp,
			Protocol:         aws.String(data["lb_protocol"].(string)),
		}

		if v, ok := data["ssl_certificate_id"]; ok {
			l.SSLCertificateID = aws.String(v.(string))
		}

		listeners = append(listeners, l)
	}

	return listeners, nil
}

// Takes the result of flatmap. Expand for an array of listeners and
// returns ECS Volume compatible objects
func expandEcsVolumes(configured []interface{}) ([]*ecs.Volume, error) {
	volumes := make([]*ecs.Volume, 0, len(configured))

	// Loop over our configured volumes and create
	// an array of aws-sdk-go compatible objects
	for _, lRaw := range configured {
		data := lRaw.(map[string]interface{})

		l := &ecs.Volume{
			Name: aws.String(data["name"].(string)),
			Host: &ecs.HostVolumeProperties{
				SourcePath: aws.String(data["host_path"].(string)),
			},
		}

		volumes = append(volumes, l)
	}

	return volumes, nil
}

// Takes JSON in a string. Decodes JSON into
// an array of ecs.ContainerDefinition compatible objects
func expandEcsContainerDefinitions(rawDefinitions string) ([]*ecs.ContainerDefinition, error) {
	var definitions []*ecs.ContainerDefinition

	err := json.Unmarshal([]byte(rawDefinitions), &definitions)
	if err != nil {
		return nil, fmt.Errorf("Error decoding JSON: %s", err)
	}

	return definitions, nil
}

// Takes the result of flatmap. Expand for an array of load balancers and
// returns ecs.LoadBalancer compatible objects
func expandEcsLoadBalancers(configured []interface{}) []*ecs.LoadBalancer {
	loadBalancers := make([]*ecs.LoadBalancer, 0, len(configured))

	// Loop over our configured load balancers and create
	// an array of aws-sdk-go compatible objects
	for _, lRaw := range configured {
		data := lRaw.(map[string]interface{})

		l := &ecs.LoadBalancer{
			ContainerName:    aws.String(data["container_name"].(string)),
			ContainerPort:    aws.Long(int64(data["container_port"].(int))),
			LoadBalancerName: aws.String(data["elb_name"].(string)),
		}

		loadBalancers = append(loadBalancers, l)
	}

	return loadBalancers
}

// Takes the result of flatmap.Expand for an array of ingress/egress security
// group rules and returns EC2 API compatible objects. This function will error
// if it finds invalid permissions input, namely a protocol of "-1" with either
// to_port or from_port set to a non-zero value.
func expandIPPerms(
	group *ec2.SecurityGroup, configured []interface{}) ([]*ec2.IPPermission, error) {
	vpc := group.VPCID != nil

	perms := make([]*ec2.IPPermission, len(configured))
	for i, mRaw := range configured {
		var perm ec2.IPPermission
		m := mRaw.(map[string]interface{})

		perm.FromPort = aws.Long(int64(m["from_port"].(int)))
		perm.ToPort = aws.Long(int64(m["to_port"].(int)))
		perm.IPProtocol = aws.String(m["protocol"].(string))

		// When protocol is "-1", AWS won't store any ports for the
		// rule, but also won't error if the user specifies ports other
		// than '0'. Force the user to make a deliberate '0' port
		// choice when specifying a "-1" protocol, and tell them about
		// AWS's behavior in the error message.
		if *perm.IPProtocol == "-1" && (*perm.FromPort != 0 || *perm.ToPort != 0) {
			return nil, fmt.Errorf(
				"from_port (%d) and to_port (%d) must both be 0 to use the the 'ALL' \"-1\" protocol!",
				*perm.FromPort, *perm.ToPort)
		}

		var groups []string
		if raw, ok := m["security_groups"]; ok {
			list := raw.(*schema.Set).List()
			for _, v := range list {
				groups = append(groups, v.(string))
			}
		}
		if v, ok := m["self"]; ok && v.(bool) {
			if vpc {
				groups = append(groups, *group.GroupID)
			} else {
				groups = append(groups, *group.GroupName)
			}
		}

		if len(groups) > 0 {
			perm.UserIDGroupPairs = make([]*ec2.UserIDGroupPair, len(groups))
			for i, name := range groups {
				ownerId, id := "", name
				if items := strings.Split(id, "/"); len(items) > 1 {
					ownerId, id = items[0], items[1]
				}

				perm.UserIDGroupPairs[i] = &ec2.UserIDGroupPair{
					GroupID: aws.String(id),
					UserID:  aws.String(ownerId),
				}
				if !vpc {
					perm.UserIDGroupPairs[i].GroupID = nil
					perm.UserIDGroupPairs[i].GroupName = aws.String(id)
					perm.UserIDGroupPairs[i].UserID = nil
				}
			}
		}

		if raw, ok := m["cidr_blocks"]; ok {
			list := raw.([]interface{})
			for _, v := range list {
				perm.IPRanges = append(perm.IPRanges, &ec2.IPRange{CIDRIP: aws.String(v.(string))})
			}
		}

		perms[i] = &perm
	}

	return perms, nil
}

// Takes the result of flatmap.Expand for an array of parameters and
// returns Parameter API compatible objects
func expandParameters(configured []interface{}) ([]*rds.Parameter, error) {
	parameters := make([]*rds.Parameter, 0, len(configured))

	// Loop over our configured parameters and create
	// an array of aws-sdk-go compatabile objects
	for _, pRaw := range configured {
		data := pRaw.(map[string]interface{})

		p := &rds.Parameter{
			ApplyMethod:    aws.String(data["apply_method"].(string)),
			ParameterName:  aws.String(data["name"].(string)),
			ParameterValue: aws.String(data["value"].(string)),
		}

		parameters = append(parameters, p)
	}

	return parameters, nil
}

// Flattens a health check into something that flatmap.Flatten()
// can handle
func flattenHealthCheck(check *elb.HealthCheck) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, 1)

	chk := make(map[string]interface{})
	chk["unhealthy_threshold"] = *check.UnhealthyThreshold
	chk["healthy_threshold"] = *check.HealthyThreshold
	chk["target"] = *check.Target
	chk["timeout"] = *check.Timeout
	chk["interval"] = *check.Interval

	result = append(result, chk)

	return result
}

// Flattens an array of UserSecurityGroups into a []string
func flattenSecurityGroups(list []*ec2.UserIDGroupPair) []string {
	result := make([]string, 0, len(list))
	for _, g := range list {
		result = append(result, *g.GroupID)
	}
	return result
}

// Flattens an array of Instances into a []string
func flattenInstances(list []*elb.Instance) []string {
	result := make([]string, 0, len(list))
	for _, i := range list {
		result = append(result, *i.InstanceID)
	}
	return result
}

// Expands an array of String Instance IDs into a []Instances
func expandInstanceString(list []interface{}) []*elb.Instance {
	result := make([]*elb.Instance, 0, len(list))
	for _, i := range list {
		result = append(result, &elb.Instance{InstanceID: aws.String(i.(string))})
	}
	return result
}

// Flattens an array of Backend Descriptions into a a map of instance_port to policy names.
func flattenBackendPolicies(backends []*elb.BackendServerDescription) map[int64][]string {
	policies := make(map[int64][]string)
	for _, i := range backends {
		for _, p := range i.PolicyNames {
			policies[*i.InstancePort] = append(policies[*i.InstancePort], *p)
		}
		sort.Strings(policies[*i.InstancePort])
	}
	return policies
}

// Flattens an array of Listeners into a []map[string]interface{}
func flattenListeners(list []*elb.ListenerDescription) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, len(list))
	for _, i := range list {
		l := map[string]interface{}{
			"instance_port":     *i.Listener.InstancePort,
			"instance_protocol": strings.ToLower(*i.Listener.InstanceProtocol),
			"lb_port":           *i.Listener.LoadBalancerPort,
			"lb_protocol":       strings.ToLower(*i.Listener.Protocol),
		}
		// SSLCertificateID is optional, and may be nil
		if i.Listener.SSLCertificateID != nil {
			l["ssl_certificate_id"] = *i.Listener.SSLCertificateID
		}
		result = append(result, l)
	}
	return result
}

// Flattens an array of Volumes into a []map[string]interface{}
func flattenEcsVolumes(list []*ecs.Volume) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, len(list))
	for _, volume := range list {
		l := map[string]interface{}{
			"name":      *volume.Name,
			"host_path": *volume.Host.SourcePath,
		}
		result = append(result, l)
	}
	return result
}

// Flattens an array of ECS LoadBalancers into a []map[string]interface{}
func flattenEcsLoadBalancers(list []*ecs.LoadBalancer) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, len(list))
	for _, loadBalancer := range list {
		l := map[string]interface{}{
			"elb_name":       *loadBalancer.LoadBalancerName,
			"container_name": *loadBalancer.ContainerName,
			"container_port": *loadBalancer.ContainerPort,
		}
		result = append(result, l)
	}
	return result
}

// Encodes an array of ecs.ContainerDefinitions into a JSON string
func flattenEcsContainerDefinitions(definitions []*ecs.ContainerDefinition) (string, error) {
	byteArray, err := json.Marshal(definitions)
	if err != nil {
		return "", fmt.Errorf("Error encoding to JSON: %s", err)
	}

	n := bytes.Index(byteArray, []byte{0})
	return string(byteArray[:n]), nil
}

// Flattens an array of Parameters into a []map[string]interface{}
func flattenParameters(list []*rds.Parameter) []map[string]interface{} {
	result := make([]map[string]interface{}, 0, len(list))
	for _, i := range list {
		result = append(result, map[string]interface{}{
			"name":  strings.ToLower(*i.ParameterName),
			"value": strings.ToLower(*i.ParameterValue),
		})
	}
	return result
}

// Takes the result of flatmap.Expand for an array of strings
// and returns a []string
func expandStringList(configured []interface{}) []*string {
	vs := make([]*string, 0, len(configured))
	for _, v := range configured {
		vs = append(vs, aws.String(v.(string)))
	}
	return vs
}

//Flattens an array of private ip addresses into a []string, where the elements returned are the IP strings e.g. "192.168.0.0"
func flattenNetworkInterfacesPrivateIPAddesses(dtos []*ec2.NetworkInterfacePrivateIPAddress) []string {
	ips := make([]string, 0, len(dtos))
	for _, v := range dtos {
		ip := *v.PrivateIPAddress
		ips = append(ips, ip)
	}
	return ips
}

//Flattens security group identifiers into a []string, where the elements returned are the GroupIDs
func flattenGroupIdentifiers(dtos []*ec2.GroupIdentifier) []string {
	ids := make([]string, 0, len(dtos))
	for _, v := range dtos {
		group_id := *v.GroupID
		ids = append(ids, group_id)
	}
	return ids
}

//Expands an array of IPs into a ec2 Private IP Address Spec
func expandPrivateIPAddesses(ips []interface{}) []*ec2.PrivateIPAddressSpecification {
	dtos := make([]*ec2.PrivateIPAddressSpecification, 0, len(ips))
	for i, v := range ips {
		new_private_ip := &ec2.PrivateIPAddressSpecification{
			PrivateIPAddress: aws.String(v.(string)),
		}

		new_private_ip.Primary = aws.Boolean(i == 0)

		dtos = append(dtos, new_private_ip)
	}
	return dtos
}

//Flattens network interface attachment into a map[string]interface
func flattenAttachment(a *ec2.NetworkInterfaceAttachment) map[string]interface{} {
	att := make(map[string]interface{})
	att["instance"] = *a.InstanceID
	att["device_index"] = *a.DeviceIndex
	att["attachment_id"] = *a.AttachmentID
	return att
}

func flattenResourceRecords(recs []*route53.ResourceRecord) []string {
	strs := make([]string, 0, len(recs))
	for _, r := range recs {
		if r.Value != nil {
			s := strings.Replace(*r.Value, "\"", "", 2)
			strs = append(strs, s)
		}
	}
	return strs
}

func expandResourceRecords(recs []interface{}, typeStr string) []*route53.ResourceRecord {
	records := make([]*route53.ResourceRecord, 0, len(recs))
	for _, r := range recs {
		s := r.(string)
		switch typeStr {
		case "TXT":
			str := fmt.Sprintf("\"%s\"", s)
			records = append(records, &route53.ResourceRecord{Value: aws.String(str)})
		default:
			records = append(records, &route53.ResourceRecord{Value: aws.String(s)})
		}
	}
	return records
}
