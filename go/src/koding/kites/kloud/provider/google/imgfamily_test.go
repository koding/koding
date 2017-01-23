package google

import (
	"reflect"
	"testing"
)

var getFromFamilyFixture = map[string]string{
	"ubuntu-os-cloud/ubuntu-1404-lts":            "ubuntu-1404-trusty-v20161010",
	"ubuntu-os-cloud/ubuntu-1604-lts":            "ubuntu-1604-xenial-v20161013",
	"windows-sql-cloud/sql-std-2016-win-2012-r2": "sql-2016-standard-windows-2012-r2-dc-v20161012",
	"rhel-cloud/rhel-7":                          "rhel-7-v20160921",
	"coreos-cloud/coreos-stable":                 "coreos-stable-1122-2-0-v20160906",
}

var getFromFamilyTestFunc = func(project, family string) string {
	return getFromFamilyFixture[project+"/"+family]
}

func TestFamily2Image(t *testing.T) {
	tests := []struct {
		Name     string
		Disks    interface{}
		Expected interface{}
	}{
		{
			Name: "non map array",
			Disks: map[string]interface{}{
				"image": "ubuntu-1604-lts",
			},
			Expected: map[string]interface{}{
				"image": "ubuntu-1604-lts",
			},
		},
		{
			Name: "no image family",
			Disks: []map[string]interface{}{
				{
					"image": "ubuntu-1204-precise-v20161010",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "ubuntu-1204-precise-v20161010",
				},
			},
		},
		{
			Name: "ubuntu family",
			Disks: []map[string]interface{}{
				{
					"image": "ubuntu-1404-lts",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
				},
			},
		},
		{
			Name: "multi images with family",
			Disks: []map[string]interface{}{
				{
					"image": "sql-std-2016-win-2012-r2",
				},
				{
					"image": "rhel-7",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "sql-2016-standard-windows-2012-r2-dc-v20161012",
				},
				{
					"image": "rhel-7-v20160921",
				},
			},
		},
		{
			Name: "unknown coreos family",
			Disks: []map[string]interface{}{
				{
					"image": "coreos-gamma",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "coreos-gamma",
				},
			},
		},
		{
			Name: "unknown coreos family",
			Disks: []map[string]interface{}{
				{
					"image": "coreos-gamma",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "coreos-gamma",
				},
			},
		},
		{
			Name: "mixed family non family",
			Disks: []map[string]interface{}{
				{
					"image": "coreos-stable",
				},
				{
					"image": "coreos-stable-1122-2-0-v20160906",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "coreos-stable-1122-2-0-v20160906",
				},
				{
					"image": "coreos-stable-1122-2-0-v20160906",
				},
			},
		},
		{
			Name: "reused cache",
			Disks: []map[string]interface{}{
				{
					"image": "ubuntu-1404-lts",
				},
				{
					"image": "ubuntu-1404-lts",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
				},
				{
					"image": "ubuntu-1404-trusty-v20161010",
				},
			},
		},
	}

	for _, test := range tests {
		// capture range variable here
		test := test
		t.Run(test.Name, func(t *testing.T) {
			t.Parallel()
			f2i := Family2Image{
				GetFromFamily: getFromFamilyTestFunc,
			}

			disks := f2i.Replace(test.Disks)
			if !reflect.DeepEqual(disks, test.Expected) {
				t.Fatalf("want disks = %#v; got %#v", test.Expected, disks)
			}
		})
	}
}
