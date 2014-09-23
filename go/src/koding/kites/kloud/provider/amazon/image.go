package amazon

import (
	"koding/kites/kloud/packer"
	"koding/kites/kloud/utils"
	"github.com/mitchellh/goamz/ec2"
)

// Builder to be used for automatic AMI building with packer
type ImageBuilder struct {
	// Credentials
	AccessKey string `packer:"access_key"`
	SecretKey string `packer:"secret_key"`

	// Name of AMI to create
	AmiName string `packer:"ami_name"`

	// Type of instance to create AMI for
	InstanceType string `packer:"instance_type"`

	// Source AMI to build off
	SourceAmi string `packer:"source_ami"`

	// AWS region to build AMI in
	Region string `packer:"region"`

	// SSH login username
	SshUsername string `packer:"ssh_username"`

	// Type of build ("amazon-ebs")
	Type string `packer:"type"`
}

// CreateImage creates an image using Packer. It uses aws.Builder
// data. It returns the image info.
func (a *AmazonClient) CreateImage(builder *ImageBuilder, provisioner interface{}) (*ec2.Image, error) {
	data, err := utils.TemplateData(builder, provisioner)
	if err != nil {
		return nil, err
	}

	provider := &packer.Provider{
		BuildName: "amazon-ebs",
		Builder:   data,
	}

	// this is basically a "packer build template.json"
	if err := provider.Build(); err != nil {
		return nil, err
	}

	// return the image result
	return a.ImageByName(builder.AmiName)
}
