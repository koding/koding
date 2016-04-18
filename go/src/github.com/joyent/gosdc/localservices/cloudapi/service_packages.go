package cloudapi

import (
	"fmt"
	"strconv"

	"github.com/joyent/gosdc/cloudapi"
)

// ListPackages lists packages in the double
func (c *CloudAPI) ListPackages(filters map[string]string) ([]cloudapi.Package, error) {
	if err := c.ProcessFunctionHook(c, filters); err != nil {
		return nil, err
	}

	availablePackages := c.packages

	if filters != nil {
		for k, f := range filters {
			// check if valid filter
			if contains(packagesFilters, k) {
				pkgs := []cloudapi.Package{}
				// filter from availablePackages and add to pkgs
				for _, p := range availablePackages {
					if k == "name" && p.Name == f {
						pkgs = append(pkgs, p)
					} else if k == "memory" {
						i, err := strconv.Atoi(f)
						if err == nil && p.Memory == i {
							pkgs = append(pkgs, p)
						}
					} else if k == "disk" {
						i, err := strconv.Atoi(f)
						if err == nil && p.Disk == i {
							pkgs = append(pkgs, p)
						}
					} else if k == "swap" {
						i, err := strconv.Atoi(f)
						if err == nil && p.Swap == i {
							pkgs = append(pkgs, p)
						}
					} else if k == "version" && p.Version == f {
						pkgs = append(pkgs, p)
					} else if k == "vcpus" {
						i, err := strconv.Atoi(f)
						if err == nil && p.VCPUs == i {
							pkgs = append(pkgs, p)
						}
					} else if k == "group" && p.Group == f {
						pkgs = append(pkgs, p)
					}
				}
				availablePackages = pkgs
			}
		}
	}

	return availablePackages, nil
}

// GetPackage gets a single package in the double
func (c *CloudAPI) GetPackage(packageName string) (*cloudapi.Package, error) {
	if err := c.ProcessFunctionHook(c, packageName); err != nil {
		return nil, err
	}

	for _, pkg := range c.packages {
		if pkg.Name == packageName {
			return &pkg, nil
		}
		if pkg.Id == packageName {
			return &pkg, nil
		}
	}

	return nil, fmt.Errorf("Package %s not found", packageName)
}
