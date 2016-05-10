package cloudapi

import (
	"fmt"

	"github.com/joyent/gosdc/cloudapi"
)

// ListImages returns a list of images in the double
func (c *CloudAPI) ListImages(filters map[string]string) ([]cloudapi.Image, error) {
	if err := c.ProcessFunctionHook(c, filters); err != nil {
		return nil, err
	}

	availableImages := c.images

	if filters != nil {
		for k, f := range filters {
			// check if valid filter
			if contains(imagesFilters, k) {
				imgs := []cloudapi.Image{}
				// filter from availableImages and add to imgs
				for _, i := range availableImages {
					if k == "name" && i.Name == f {
						imgs = append(imgs, i)
					} else if k == "os" && i.OS == f {
						imgs = append(imgs, i)
					} else if k == "version" && i.Version == f {
						imgs = append(imgs, i)
					} else if k == "public" && fmt.Sprintf("%v", i.Public) == f {
						imgs = append(imgs, i)
					} else if k == "state" && i.State == f {
						imgs = append(imgs, i)
					} else if k == "owner" && i.Owner == f {
						imgs = append(imgs, i)
					} else if k == "type" && i.Type == f {
						imgs = append(imgs, i)
					}
				}
				availableImages = imgs
			}
		}
	}

	return availableImages, nil
}

// GetImage gets a single image by name from the double
func (c *CloudAPI) GetImage(imageID string) (*cloudapi.Image, error) {
	if err := c.ProcessFunctionHook(c, imageID); err != nil {
		return nil, err
	}

	for _, image := range c.images {
		if image.Id == imageID {
			return &image, nil
		}
	}

	return nil, fmt.Errorf("Image %s not found", imageID)
}
