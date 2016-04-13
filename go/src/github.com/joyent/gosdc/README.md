# gosdc

[![wercker status](https://app.wercker.com/status/349ee60ed0afffd99d2b2b354ada5938/s/master "wercker status")](https://app.wercker.com/project/bykey/349ee60ed0afffd99d2b2b354ada5938)

`gosdc` is a Go client for Joyent's SmartDataCenter

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [gosdc](#gosdc)
    - [Usage](#usage)
        - [Examples](#examples)
    - [Resources](#resources)
    - [License](#license)

<!-- markdown-toc end -->

## Usage

To create a client
([`*cloudapi.Client`](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client)),
you'll need a few things:

1. your account ID
2. the ID of the key associated with your account
3. your private key material
4. the cloud endpoint you want to use (for example
   `https://us-east-1.api.joyentcloud.com`)
   
Given these four pieces of information, you can initialize a client with the
following (N.B. error handling is glossed over in this example for the sake of
brevity):

```go
package main

import (
	"github.com/joyent/gocommon/client"
	"github.com/joyent/gosdc/cloudapi"
	"github.com/joyent/gosign/auth"
    "io/ioutil"
)

func client(key, keyId, account, endpoint string) *cloudapi.Client {
	keyData, _ := ioutil.ReadFile(key)
	auth, _ := auth.NewAuth(account, string(keyData), "rsa-sha256")

	creds := &auth.Credentials{
    	UserAuthentication: auth,
		SdcKeyId:           keyId,
		SdcEndpoint:        endpoint,
	}
    
	return cloudapi.New(client.NewClient(
		endpoint,
		cloudapi.DefaultAPIVersion,
		creds,
		&cloudapi.Logger
	))
}
```

### Examples

Projects using the gosdc API:

 - [triton-terraform](https://github.com/joyent/triton-terraform)

## Resources

After creating a client, you can manipulate resources in the following ways:

| Resource | Create | Read | Update | Delete | Extra |
|----------|--------|------|--------|--------|-------|
| Datacenters | | [GetDatacenter](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetDatacenter), [ListDatacenters](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListDatacenters) | | | |
| Firewall Rules | [CreateFirewallRule](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.CreateFirewallRule) | [GetFirewallRule](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetFirewallRule), [ListFirewallRules](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListFirewallRules), [ListmachineFirewallRules](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListMachineFirewallRules) | [UpdateFirewallRule](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.UpdateFirewallRule), [EnableFirewallRule](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.EnableFirewallRule), [DisableFirewallRule](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DisableFirewallRule) | [DeleteFirewallRule](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteFirewallRule) | |
| Instrumentations | [CreateInstrumentation](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.CreateInstrumentation) | [GetInstrumentation](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetInstrumentation), [ListInstrumentations](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListInstrumentations), [GetInstrumentationHeatmap](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetInstrumentationHeatmap), [GetInstrumentationHeatmapDetails](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetInstrumentationHeatmapDetails), [GetInstrumentationValue](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetInstrumentationValue) | | [DeleteInstrumentation](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteInstrumentation) | [DescribeAnalytics](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DescribeAnalytics) |
| Keys | [CreateKey](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.CreateKey) | [GetKey](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetKey), [ListKeys](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListKeys) | | [DeleteKey](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteKey) | |
| Machines | [CreateMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.CreateMachine) | [GetMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetMachine), [ListMachines](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListMachines), [ListFirewallRuleMachines](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListFirewallRuleMachines)  | [RenameMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.RenameMachine), [ResizeMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ResizeMachine) | [DeleteMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteMachine) | [CountMachines](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.CountMachines), [MachineAudit](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.MachineAudit), [StartMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.StartMachine), [StartMachineFromSnapshot](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.StartMachineFromSnapshot), [StopMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.StopMachine), [RebootMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.RebootMachine) |
| Machine (Images) | [CreateImageFromMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.CreateImageFromMachine) | [GetImage](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetImage), [ListImages](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListImages) | | [DeleteImage](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteImage) | [ExportImage](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ExportImage) |
| Machine (Metadata) | | [GetMachineMetadata](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetMachineMetadata) | [UpdateMachineMetadata](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.UpdateMachineMetadata) | [DeleteMachineMetadata](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteMachineMetadata), [DeleteAllMachineMetadata](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteAllMachineMetadata) | |
| Machine (Snapshots) | [CreateMachineSnapshot](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.CreateMachineSnapshot) | [GetMachineSnapshot](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetMachineSnapshot), [ListMachineSnapshots](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListMachineSnapshots) | | [DeleteMachineSnapshot](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteMachineSnapshot) | |
| Machine (Tags) | | [GetMachineTag](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetMachineTag), [ListMachineTags](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListMachineTags) | [AddMachineTags](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.AddMachineTags), [ReplaceMachineTags](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ReplaceMachineTags) | [DeleteMachineTag](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteMachineTag), [DeleteMachineTags](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DeleteMachineTags) | [EnableFirewallMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.EnableFirewallMachine), [DisableFirewallMachine](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.DisableFirewallMachine) |
| Networks | | [GetNetwork](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetNetwork), [ListNetworks](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListNetworks) | | | |
| Packages | | [GetPackage](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.GetPackage), [ListPackages](https://godoc.org/github.com/joyent/gosdc/cloudapi#Client.ListPackages) | | | |

## License

gosdc is licensed under the Mozilla Public License Version 2.0, a copy of which
is available at [LICENSE](LICENSE)
