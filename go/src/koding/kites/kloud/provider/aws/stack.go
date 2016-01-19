package awsprovider

import (
	"errors"

	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stackplan"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

func init() {
	stackplan.MetaFuncs["aws"] = func() interface{} { return &AwsMeta{} }
}

var _ kloud.Validator = (*AwsMeta)(nil)

// AwsMeta represents jCredentialDatas.meta for "aws" provider.
type AwsMeta struct {
	Region    string `json:"region" bson:"region" stackplan:"region"`
	AccessKey string `json:"access_key" bson:"access_key" stackplan:"access_key"`
	SecretKey string `json:"secret_key" bson:"secret_key" stackplan:"secret_key"`

	// Bootstrap metadata:
	ACL       string `json:"acl" bson:"acl" stackplan:"acl"`
	CidrBlock string `json:"cidr_block" bson:"cidr_block" stackplan:"cidr_block"`
	IGW       string `json:"igw" bson:"igw" stackplan:"igw"`
	KeyPair   string `json:"key_pair" bson:"key_pair" stackplan:"key_pair"`
	RTB       string `json:"rtb" bson:"rtb" stackplan:"rtb"`
	SG        string `json:"sg" bson:"sg" stackplan:"sg"`
	Subnet    string `json:"subnet" bson:"subnet" stackplan:"subnet"`
	VPC       string `json:"vpc" bson:"vpc" stackplan:"vpc"`
	AMI       string `json:"ami" bson:"ami" stackplan:"ami"`
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
	Log     logging.Logger
	Req     *kite.Request
	Builder *stackplan.Builder
	Session *session.Session

	// Keys and Eventer may be nil, it depends on the context used
	// to initialize the Stack.
	Keys    *publickeys.Keys
	Eventer eventer.Eventer
}

// Ensure Provider implements the kloud.StackProvider interface.
//
// StackProvider is an interface for team kloud API.
var _ kloud.StackProvider = (*Provider)(nil)

// Stack
func (p *Provider) Stack(ctx context.Context) (kloud.Stacker, error) {
	s := &Stack{}

	var ok bool
	if s.Req, ok = request.FromContext(ctx); !ok {
		return nil, errors.New("request not available in context")
	}

	if s.Session, ok = session.FromContext(ctx); !ok {
		return nil, errors.New("session not available in context")
	}

	if groupName, ok := ctx.Value(kloud.GroupNameKey).(string); ok {
		s.Log = p.Log.New(groupName)
	} else {
		s.Log = p.Log
	}

	if keys, ok := publickeys.FromContext(ctx); ok {
		s.Keys = keys
	}

	if ev, ok := eventer.FromContext(ctx); ok {
		s.Eventer = ev
	}

	s.Builder = stackplan.NewBuilder(s.Log.New("stackplan"))

	return s, nil
}
