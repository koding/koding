package google

import (
	"reflect"
	"testing"
)

var getDiskSizeFixture = map[string]int{
	"ubuntu-os-cloud/ubuntu-1404-trusty-v20161010":                     10,
	"windows-sql-cloud/sql-2016-standard-windows-2012-r2-dc-v20161012": 50,
	"/custom_image": 24,
}

var getDiskSizeFixtureFunc = func(project, image string) int {
	return getDiskSizeFixture[project+"/"+image]
}

func TestImage2Size(t *testing.T) {
	tests := []struct {
		Name     string
		Disks    interface{}
		Expected interface{}
	}{
		{
			Name: "non map array",
			Disks: map[string]interface{}{
				"image": "ubuntu-1404-trusty-v20161010",
			},
			Expected: map[string]interface{}{
				"image": "ubuntu-1404-trusty-v20161010",
			},
		},
		{
			Name: "ubuntu image",
			Disks: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
					"type":  "pd-standard",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
					"type":  "pd-standard",
					"size":  10,
				},
			},
		},
		{
			Name: "disk size not supported",
			Disks: []map[string]interface{}{
				{
					"disk": "custom_image",
				},
			},
			Expected: []map[string]interface{}{
				{
					"disk": "custom_image",
				},
			},
		},
		{
			Name: "local ssd skip",
			Disks: []map[string]interface{}{
				{
					"image": "sql-2016-standard-windows-2012-r2-dc-v20161012",
					"type":  "local-ssd",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "sql-2016-standard-windows-2012-r2-dc-v20161012",
					"type":  "local-ssd",
				},
			},
		},
		{
			Name: "size already specified",
			Disks: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
					"size":  16,
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
					"size":  16,
				},
			},
		},
		{
			Name: "disk and image skip",
			Disks: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
					"disk":  "custom_image",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "ubuntu-1404-trusty-v20161010",
					"disk":  "custom_image",
				},
			},
		},
		{
			Name: "custom image",
			Disks: []map[string]interface{}{
				{
					"image": "custom_image",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "custom_image",
					"size":  24,
				},
			},
		},
		{
			Name: "multi disks",
			Disks: []map[string]interface{}{
				{
					"image": "custom_image",
				},
				{
					"image": "sql-2016-standard-windows-2012-r2-dc-v20161012",
				},
			},
			Expected: []map[string]interface{}{
				{
					"image": "custom_image",
					"size":  24,
				},
				{
					"image": "sql-2016-standard-windows-2012-r2-dc-v20161012",
					"size":  50,
				},
			},
		},
	}

	for _, test := range tests {
		// capture range variable here
		test := test
		t.Run(test.Name, func(t *testing.T) {
			t.Parallel()
			f2i := Image2Size{
				GetDiskSize: getDiskSizeFixtureFunc,
			}

			disks := f2i.Replace(test.Disks)
			if !reflect.DeepEqual(disks, test.Expected) {
				t.Fatalf("want disks = %#v; got %#v", test.Expected, disks)
			}
		})
	}
}
