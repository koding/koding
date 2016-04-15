package dns

import (
	"testing"

	"github.com/abdullin/seq"
	"github.com/jen20/riviera/azure"
	"github.com/jen20/riviera/test"
)

func TestAccCreateDnsZone(t *testing.T) {
	rgName := test.RandPrefixString("testrg_", 20)
	zoneName := test.RandString(10) + ".com"

	test.Test(t, test.TestCase{
		Steps: []test.Step{
			&test.StepRegisterResourceProvider{
				Namespace: "Microsoft.Network",
			},
			&test.StepCreateResourceGroup{
				Name:     rgName,
				Location: azure.WestUS,
			},
			&test.StepRunCommand{
				StateBagKey: "dnszone",
				RunCommand: &CreateDNSZone{
					Name:              zoneName,
					ResourceGroupName: rgName,
					Location:          azure.Global,
					Tags: map[string]*string{
						"Purpose": azure.String("Acceptance Testing"),
					},
				},
				StateCommand: &GetDNSZone{
					Name:              zoneName,
					ResourceGroupName: rgName,
				},
				CleanupCommand: &DeleteDNSZone{
					Name:              zoneName,
					ResourceGroupName: rgName,
				},
			},
			&test.StepAssert{
				StateBagKey: "dnszone",
				Assertions: seq.Map{
					"Name":               zoneName,
					"NumberOfRecordSets": 2,
				},
			},
		},
	})
}

func TestAccCreateDnsARecordSet(t *testing.T) {
	rgName := test.RandPrefixString("testrg_", 20)
	zoneName := test.RandString(10) + ".com"
	recordSetName := test.RandPrefixString("rs_", 10)

	test.Test(t, test.TestCase{
		Steps: []test.Step{
			&test.StepRegisterResourceProvider{
				Namespace: "Microsoft.Network",
			},
			&test.StepCreateResourceGroup{
				Name:     rgName,
				Location: azure.WestUS,
			},
			&test.StepRunCommand{
				StateBagKey: "dnszone",
				RunCommand: &CreateDNSZone{
					Name:              zoneName,
					ResourceGroupName: rgName,
					Location:          azure.Global,
					Tags: map[string]*string{
						"Purpose": azure.String("Acceptance Testing"),
					},
				},
				StateCommand: &GetDNSZone{
					Name:              zoneName,
					ResourceGroupName: rgName,
				},
				CleanupCommand: &DeleteDNSZone{
					Name:              zoneName,
					ResourceGroupName: rgName,
				},
			},
			&test.StepRunCommand{
				StateBagKey: "dnsrecordset",
				RunCommand: &CreateARecordSet{
					Name:              recordSetName,
					ZoneName:          zoneName,
					ResourceGroupName: rgName,
					Location:          azure.Global,
					Tags: map[string]*string{
						"Purpose": azure.String("Acceptance Testing"),
					},
					TTL: 300,
					ARecords: []ARecord{
						ARecord{
							IPv4Address: "10.0.10.1",
						},
						ARecord{
							IPv4Address: "10.0.10.2",
						},
					},
				},
				StateCommandURIKey: "ID",
				StateCommand:       &GetARecordSet{},
				CleanupCommand: &DeleteRecordSet{
					Name:              recordSetName,
					ZoneName:          zoneName,
					ResourceGroupName: rgName,
					RecordSetType:     "A",
				},
			},
			&test.StepAssert{
				StateBagKey: "dnsrecordset",
				Assertions: seq.Map{
					"TTL":                     300,
					"Name":                    recordSetName,
					"Location":                azure.Global,
					"ARecords[0].ipv4Address": "10.0.10.1",
					"ARecords[1].ipv4Address": "10.0.10.2",
				},
			},
		},
	})
}
