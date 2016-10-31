package google

import "strings"

// Image2Size is used to find and map image disk sizes when they are not
// provided. This structure was created in order to discover and attach image
// sizes to terraform template. Thus, they will be visible(and valid as
// metadata) when user run terraform plan.
type Image2Size struct {
	GetDiskSize func(project, image string) int

	// cache is used to avoid looking for image disk sizes that were already
	// found.
	cache map[string]int
}

// Replace gets disk data and adds `size` field for all images which don't
// explicitly specify their sizes. This function is not intended to add `size`
// field when either `disk` field or `local-ssd` type is specified.
func (is *Image2Size) Replace(disks interface{}) interface{} {
	if is.GetDiskSize == nil {
		return disks
	}

	if is.cache == nil {
		is.cache = make(map[string]int)
	}

	items, ok := disks.([]map[string]interface{})
	if !ok {
		return disks
	}

	for i := range items {
		if items[i] == nil {
			continue
		}

		// Skip when size is already set.
		if _, ok := items[i]["size"]; ok {
			continue
		}

		// Disk size discovery is not supported here.
		if _, ok := items[i]["disk"]; ok {
			continue
		}

		// Do not attach size field when disk type is local-ssd.
		if typ, ok := items[i]["type"]; ok {
			if name, ok := typ.(string); ok && name == "local-ssd" {
				continue
			}
		}

		// User doesn't have to provide image name.
		image, ok := items[i]["image"]
		if !ok {
			continue
		}

		size := is.getSize(image)
		if size == 0 {
			continue
		}

		items[i]["size"] = size
	}

	return items
}

func (is *Image2Size) getSize(name interface{}) int {
	// Invalid value will be caught later by terraform.
	if name == nil {
		return 0
	}

	image, ok := name.(string)
	if !ok {
		return 0
	}

	// Get from cache.
	if size, ok := is.cache[image]; ok {
		return size
	}

	size := is.GetDiskSize(imageProject(image), image)
	if size == 0 {
		return 0
	}

	is.cache[image] = size
	return size
}

var image2project = map[string]string{
	"windows": "windows-cloud",
	"ubuntu":  "ubuntu-os-cloud",
	"rhel":    "rhel-cloud",
	"sql":     "windows-sql-cloud",
	"debian":  "debian-cloud",
	"coreos":  "coreos-cloud",
	"centos":  "centos-cloud",
	"sles":    "suse-cloud",
}

// imageProject looks up for the respective image project.
func imageProject(image string) string {
	for prefix, project := range image2project {
		if strings.HasPrefix(image, prefix) {
			return project
		}
	}

	return ""
}
