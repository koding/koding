package test

import (
	"testing"

	"github.com/abdullin/seq"
	"github.com/jen20/riviera/azure"
)

func TestAccCreateResourceGroup(t *testing.T) {
	rgName := RandPrefixString("testrg_", 20)

	Test(t, TestCase{
		Steps: []Step{
			&StepCreateResourceGroup{
				Name:     rgName,
				Location: azure.WestUS,
			},
			&StepAssert{
				StateBagKey: "resourcegroup",
				Assertions: seq.Map{
					"Name":     rgName,
					"Location": azure.WestUS,
				},
			},
		},
	})
}

func TestAccUpdateResourceGroup(t *testing.T) {
	rgName := RandPrefixString("testrg_", 20)

	Test(t, TestCase{
		Steps: []Step{
			&StepCreateResourceGroup{
				Name:     rgName,
				Location: azure.WestUS,
			},
			&StepAssert{
				StateBagKey: "resourcegroup",
				Assertions: seq.Map{
					"Name":     rgName,
					"Location": azure.WestUS,
				},
			},
			&StepRunCommand{
				StateBagKey: "resourcegroup",
				RunCommand: &azure.UpdateResourceGroup{
					Name: rgName,
					Tags: map[string]*string{
						"Purpose": azure.String("Acceptance Testing"),
					},
				},
				StateCommand: &azure.GetResourceGroup{
					Name: rgName,
				},
			},
			&StepAssert{
				StateBagKey: "resourcegroup",
				Assertions: seq.Map{
					"Name":         rgName,
					"Tags.Purpose": "Acceptance Testing",
				},
			},
		},
	})
}
