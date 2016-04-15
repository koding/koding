/*
Copyright (c) 2015 VMware, Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package vnic

import (
	"flag"
	"fmt"
	"strings"

	"github.com/vmware/govmomi/govc/cli"
	"github.com/vmware/govmomi/govc/flags"
	"github.com/vmware/govmomi/vim25/types"
	"golang.org/x/net/context"
)

type service struct {
	*flags.HostSystemFlag

	Enable  bool
	Disable bool
}

func init() {
	cli.Register("host.vnic.service", &service{})
}

func (cmd *service) Register(ctx context.Context, f *flag.FlagSet) {
	cmd.HostSystemFlag, ctx = flags.NewHostSystemFlag(ctx)
	cmd.HostSystemFlag.Register(ctx, f)

	f.BoolVar(&cmd.Enable, "enable", false, "Enable service")
	f.BoolVar(&cmd.Disable, "disable", false, "Disable service")
}

func (cmd *service) Process(ctx context.Context) error {
	if err := cmd.HostSystemFlag.Process(ctx); err != nil {
		return err
	}
	// Either may be true or none may be true.
	if cmd.Enable && cmd.Disable {
		return flag.ErrHelp
	}

	return nil
}

func (cmd *service) Usage() string {
	return "SERVICE DEVICE"
}

func (cmd *service) Description() string {
	nicTypes := []string{
		string(types.HostVirtualNicManagerNicTypeVmotion),
		string(types.HostVirtualNicManagerNicTypeFaultToleranceLogging),
		string(types.HostVirtualNicManagerNicTypeVSphereReplication),
		string(types.HostVirtualNicManagerNicTypeVSphereReplicationNFC),
		string(types.HostVirtualNicManagerNicTypeManagement),
		string(types.HostVirtualNicManagerNicTypeVsan),
		string(types.HostVirtualNicManagerNicTypeVSphereProvisioning),
	}

	return fmt.Sprintf(`
Enable or disable service on a virtual nic device.  Example:
SERVICE [%s] DEVICE [%s]`, strings.Join(nicTypes, "|"), strings.Join([]string{"vmk0", "vmk1", "..."}, "|"))
}

func (cmd *service) Run(ctx context.Context, f *flag.FlagSet) error {
	if f.NArg() != 2 {
		return flag.ErrHelp
	}

	service := f.Arg(0)
	device := f.Arg(1)

	host, err := cmd.HostSystem()
	if err != nil {
		return err
	}

	m, err := host.ConfigManager().VirtualNicManager(ctx)
	if err != nil {
		return err
	}

	var method func(context.Context, string, string) error

	if cmd.Enable {
		method = m.SelectVnic
	} else if cmd.Disable {
		method = m.DeselectVnic
	}

	if method == nil {
		return flag.ErrHelp
	}

	return method(ctx, service, device)
}
