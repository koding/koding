package awsprovider

import (
	"errors"

	"koding/kites/kloud/kloud"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stackplan"

	"golang.org/x/net/context"
)

func init() {
	stackplan.MetaFuncs["aws"] = func() interface{} { return &AwsMeta{} }
}

var _ kloud.Validator = (*AwsMeta)(nil)

// AwsMeta represents jCredentialDatas.meta for "aws" provider.
type AwsMeta struct {
	Region    string `json:"region" bson:"region" hcl:"region"`
	AccessKey string `json:"access_key" bson:"access_key" hcl:"access_key"`
	SecretKey string `json:"secret_key" bson:"secret_key" hcl:"secret_key"`

	// Bootstrap metadata:
	ACL       string `json:"acl" bson:"acl" hcl:"acl"`
	CidrBlock string `json:"cidr_block" bson:"cidr_block" hcl:"cidr_block"`
	IGW       string `json:"igw" bson:"igw" hcl:"igw"`
	KeyPair   string `json:"key_pair" bson:"key_pair" hcl:"key_pair"`
	RTB       string `json:"rtb" bson:"rtb" hcl:"rtb"`
	SG        string `json:"sg" bson:"sg" hcl:"sg"`
	Subnet    string `json:"subnet" bson:"subnet" hcl:"subnet"`
	VPC       string `json:"vpc" bson:"vpc" hcl:"vpc"`
	AMI       string `json:"ami" bson:"ami" hcl:"ami"`
}

// IsBootstrapComplete says whether all bootstrap-related fields are non-zero.
func (meta *AwsMeta) IsBootstrapComplete() bool {
	// TODO(rjeczalik): automate, add tag option?
	bootstrap := []string{
		meta.ACL, meta.CidrBlock, meta.IGW, meta.KeyPair, meta.RTB,
		meta.SG, meta.Subnet, meta.VPC, meta.AMI,
	}
	for _, s := range bootstrap {
		if s == "" {
			return false
		}
	}

	return true
}

// Valid implements the kloud.Validator interface.
func (meta *AwsMeta) Valid() error {
	if meta.Region == "" {
		return errors.New("aws meta: region is empty")
	}
	if meta.AccessKey == "" {
		return errors.New("aws meta: access key is empty")
	}
	if meta.SecretKey == "" {
		return errors.New("aws meta: secret key is empty")
	}
	return nil
}

// Stack
type Stack struct {
	*provider.BaseStack
}

// Ensure Provider implements the kloud.StackProvider interface.
//
// StackProvider is an interface for team kloud API.
var _ kloud.StackProvider = (*Provider)(nil)

// Stack
func (p *Provider) Stack(ctx context.Context) (kloud.Stacker, error) {
	bs, err := provider.NewBaseStack(ctx, p.Log)
	if err != nil {
		return nil, err
	}

	return &Stack{
		BaseStack: bs,
	}, nil
}
