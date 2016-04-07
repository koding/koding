package list

import (
	"sort"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"koding/klient/remote/machine"
	"koding/klient/remote/restypes"
)

func newKiteInfo(vmName string, status machine.MachineStatus) KiteInfo {
	info := KiteInfo{restypes.ListMachineInfo{
		VMName:        vmName,
		MachineStatus: status,
	}}

	if status == machine.MachineConnected || status == machine.MachineDisconnected {
		info.Mounts = []restypes.ListMountInfo{restypes.ListMountInfo{}}
	}

	return info
}

func namesFromKiteInfos(infos KiteInfos) []string {
	names := make([]string, len(infos))
	for i, info := range infos {
		names[i] = info.VMName
	}
	return names
}

func TestKiteInfosSort(t *testing.T) {
	Convey("Given a list of varied machines", t, func() {
		infos := KiteInfos{
			newKiteInfo("coconut", machine.MachineDisconnected),
			newKiteInfo("apple", machine.MachineOffline),
			newKiteInfo("pear", machine.MachineOnline),
			newKiteInfo("date", machine.MachineOnline),
			newKiteInfo("grapefruit", machine.MachineOffline),
			newKiteInfo("orange", machine.MachineOffline),
			newKiteInfo("banana", machine.MachineOffline),
			newKiteInfo("squash", machine.MachineConnected),
			newKiteInfo("kiwi", machine.MachineOnline),
			newKiteInfo("jackfruit", machine.MachineConnected),
		}

		Convey("It should sort them as expected", func() {
			expected := []string{
				"coconut",
				"jackfruit",
				"squash",
				"date",
				"kiwi",
				"pear",
				"apple",
				"banana",
				"grapefruit",
				"orange",
			}

			sort.Sort(infos)
			So(namesFromKiteInfos(infos), ShouldResemble, expected)
		})
	})
}
