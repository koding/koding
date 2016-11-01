package google

import "strings"

// Family2Image is used to map image families into their latest images.
type Family2Image struct {
	GetFromFamily func(project, family string) string

	// cache is used to avoid looking for images that were already found.
	cache map[string]string
}

// Replace gets disk data and replaces each image fields that contain image
// family with the lasted image that is a part of that family.
func (f *Family2Image) Replace(disks interface{}) interface{} {
	if f.GetFromFamily == nil {
		return disks
	}

	if f.cache == nil {
		f.cache = make(map[string]string)
	}

	items, ok := disks.([]map[string]interface{})
	if !ok {
		return disks
	}

	for i := range items {
		if items[i] == nil {
			continue
		}

		// User doesn't have to provide image name.
		image, ok := items[i]["image"]
		if !ok {
			continue
		}

		items[i]["image"] = f.getImage(image)
	}

	return items
}

func (f *Family2Image) getImage(name interface{}) interface{} {
	// Invalid value will be caught later by terraform.
	if name == nil {
		return name
	}

	family, ok := name.(string)
	if !ok {
		return name
	}

	// Get from cache.
	if image, ok := f.cache[family]; ok {
		return image
	}

	project, ok := familyProject(family)
	if !ok {
		return name
	}

	image := f.GetFromFamily(project, family)
	if image == "" {
		return name
	}

	f.cache[family] = image
	return image
}

var family2project = map[string]string{
	"windows": "windows-cloud",
	"ubuntu":  "ubuntu-os-cloud",
	"rhel":    "rhel-cloud",
	"sql":     "windows-sql-cloud",
	"debian":  "debian-cloud",
	"coreos":  "coreos-cloud",
	"centos":  "centos-cloud",
	"sles":    "suse-cloud",
}

// familyProject checks if provided string is an image family name. If yes, this
// functions looks up for the respective image project. It returns zero value
// and `false` status if provided string is not image family identifier.
func familyProject(family string) (string, bool) {
	// Check for images with version. That has form name-additional-vYYYYMMDD
	toks := strings.Split(family, "-")
	if len(toks) > 1 && len(toks[len(toks)-1]) > 0 && toks[len(toks)-1][0] == 'v' {
		return "", false
	}

	for prefix, project := range family2project {
		if strings.HasPrefix(family, prefix) {
			return project, true
		}
	}

	return "", false
}
