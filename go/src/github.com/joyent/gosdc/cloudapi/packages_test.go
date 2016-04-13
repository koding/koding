package cloudapi_test

import (
	gc "launchpad.net/gocheck"

	"github.com/joyent/gosdc/cloudapi"
)

func (s *LocalTests) TestListPackages(c *gc.C) {
	pkgs, err := s.testClient.ListPackages(nil)
	c.Assert(err, gc.IsNil)
	c.Assert(pkgs, gc.NotNil)
	for _, pkg := range pkgs {
		c.Check(pkg.Name, gc.FitsTypeOf, string(""))
		c.Check(pkg.Memory, gc.FitsTypeOf, int(0))
		c.Check(pkg.Disk, gc.FitsTypeOf, int(0))
		c.Check(pkg.Swap, gc.FitsTypeOf, int(0))
		c.Check(pkg.VCPUs, gc.FitsTypeOf, int(0))
		c.Check(pkg.Default, gc.FitsTypeOf, bool(false))
		c.Check(pkg.Id, gc.FitsTypeOf, string(""))
		c.Check(pkg.Version, gc.FitsTypeOf, string(""))
		c.Check(pkg.Description, gc.FitsTypeOf, string(""))
		c.Check(pkg.Group, gc.FitsTypeOf, string(""))
	}
}

func (s *LocalTests) TestListPackagesWithFilter(c *gc.C) {
	filter := cloudapi.NewFilter()
	filter.Set("memory", "1024")
	pkgs, err := s.testClient.ListPackages(filter)
	c.Assert(err, gc.IsNil)
	c.Assert(pkgs, gc.NotNil)
	for _, pkg := range pkgs {
		c.Check(pkg.Name, gc.FitsTypeOf, string(""))
		c.Check(pkg.Memory, gc.Equals, 1024)
		c.Check(pkg.Disk, gc.FitsTypeOf, int(0))
		c.Check(pkg.Swap, gc.FitsTypeOf, int(0))
		c.Check(pkg.VCPUs, gc.FitsTypeOf, int(0))
		c.Check(pkg.Default, gc.FitsTypeOf, bool(false))
		c.Check(pkg.Id, gc.FitsTypeOf, string(""))
		c.Check(pkg.Version, gc.FitsTypeOf, string(""))
		c.Check(pkg.Description, gc.FitsTypeOf, string(""))
		c.Check(pkg.Group, gc.FitsTypeOf, string(""))
	}
}

func (s *LocalTests) TestGetPackageFromName(c *gc.C) {
	key, err := s.testClient.GetPackage(localPackageName)
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Package{
		Name:    "Small",
		Memory:  1024,
		Disk:    16384,
		Swap:    2048,
		VCPUs:   1,
		Default: true,
		Id:      "11223344-1212-abab-3434-aabbccddeeff",
		Version: "1.0.2",
	})
}

func (s *LocalTests) TestGetPackageFromId(c *gc.C) {
	key, err := s.testClient.GetPackage(localPackageID)
	c.Assert(err, gc.IsNil)
	c.Assert(key, gc.NotNil)
	c.Assert(key, gc.DeepEquals, &cloudapi.Package{
		Name:    "Small",
		Memory:  1024,
		Disk:    16384,
		Swap:    2048,
		VCPUs:   1,
		Default: true,
		Id:      "11223344-1212-abab-3434-aabbccddeeff",
		Version: "1.0.2",
	})
}
