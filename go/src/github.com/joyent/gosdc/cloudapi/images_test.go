package cloudapi_test

import (
	gc "launchpad.net/gocheck"

	"github.com/joyent/gosdc/cloudapi"
)

// Images API
func (s *LocalTests) TestListImages(c *gc.C) {
	imgs, err := s.testClient.ListImages(nil)
	c.Assert(err, gc.IsNil)
	c.Assert(imgs, gc.NotNil)
	for _, img := range imgs {
		c.Check(img.Id, gc.FitsTypeOf, string(""))
		c.Check(img.Name, gc.FitsTypeOf, string(""))
		c.Check(img.OS, gc.FitsTypeOf, string(""))
		c.Check(img.Version, gc.FitsTypeOf, string(""))
		c.Check(img.Type, gc.FitsTypeOf, string(""))
		c.Check(img.Description, gc.FitsTypeOf, string(""))
		c.Check(img.Requirements, gc.FitsTypeOf, map[string]interface{}{"key": "value"})
		c.Check(img.Homepage, gc.FitsTypeOf, string(""))
		c.Check(img.PublishedAt, gc.FitsTypeOf, string(""))
		c.Check(img.Public, gc.FitsTypeOf, bool(true))
		c.Check(img.State, gc.FitsTypeOf, string(""))
		c.Check(img.Tags, gc.FitsTypeOf, map[string]string{"key": "value"})
		c.Check(img.EULA, gc.FitsTypeOf, string(""))
		c.Check(img.ACL, gc.FitsTypeOf, []string{"", ""})
	}
}

func (s *LocalTests) TestListImagesWithFilter(c *gc.C) {
	filter := cloudapi.NewFilter()
	filter.Set("os", "smartos")
	imgs, err := s.testClient.ListImages(filter)
	c.Assert(err, gc.IsNil)
	c.Assert(imgs, gc.NotNil)
	for _, img := range imgs {
		c.Check(img.Id, gc.FitsTypeOf, string(""))
		c.Check(img.Name, gc.FitsTypeOf, string(""))
		c.Check(img.OS, gc.Equals, "smartos")
		c.Check(img.Version, gc.FitsTypeOf, string(""))
		c.Check(img.Type, gc.FitsTypeOf, string(""))
		c.Check(img.Description, gc.FitsTypeOf, string(""))
		c.Check(img.Requirements, gc.FitsTypeOf, map[string]interface{}{"key": "value"})
		c.Check(img.Homepage, gc.FitsTypeOf, string(""))
		c.Check(img.PublishedAt, gc.FitsTypeOf, string(""))
		c.Check(img.Public, gc.FitsTypeOf, bool(true))
		c.Check(img.State, gc.FitsTypeOf, string(""))
		c.Check(img.Tags, gc.FitsTypeOf, map[string]string{"key": "value"})
		c.Check(img.EULA, gc.FitsTypeOf, string(""))
		c.Check(img.ACL, gc.FitsTypeOf, []string{"", ""})
	}
}

// TODO Add test for deleteImage, exportImage and CreateMachineFormIMage

func (s *LocalTests) TestGetImage(c *gc.C) {
	img, err := s.testClient.GetImage(localImageID)
	c.Assert(err, gc.IsNil)
	c.Assert(img, gc.NotNil)
	c.Assert(img, gc.DeepEquals, &cloudapi.Image{
		Id:          "12345678-a1a1-b2b2-c3c3-098765432100",
		Name:        "SmartOS Std",
		OS:          "smartos",
		Version:     "13.3.1",
		Type:        "smartmachine",
		Description: "Test SmartOS image (32 bit)",
		Homepage:    "http://test.joyent.com/Standard_Instance",
		PublishedAt: "2014-01-08T17:42:31Z",
		Public:      true,
		State:       "active",
	})
}
