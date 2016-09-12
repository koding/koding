package awsprovider

import (
	"errors"
	"fmt"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/iam"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"

	"golang.org/x/net/context"
)

func init() {
	stackplan.MetaFuncs["aws"] = func() interface{} { return &AwsMeta{} }
}

var _ stack.Validator = (*AwsMeta)(nil)

// AwsMeta represents jCredentialDatas.meta for "aws" provider.
type AwsMeta struct {
	Region    string `json:"region" bson:"region" hcl:"region"`
	AccessKey string `json:"access_key" bson:"access_key" hcl:"access_key"`
	SecretKey string `json:"secret_key" bson:"secret_key" hcl:"secret_key"`

	// Bootstrap metadata.
	ACL       string `json:"acl,omitempty" bson:"acl,omitempty" hcl:"acl"`
	CidrBlock string `json:"cidr_block,omitempty" bson:"cidr_block,omitempty" hcl:"cidr_block"`
	IGW       string `json:"igw,omitempty" bson:"igw,omitempty" hcl:"igw"`
	KeyPair   string `json:"key_pair,omitempty" bson:"key_pair,omitempty" hcl:"key_pair"`
	RTB       string `json:"rtb,omitempty" bson:"rtb,omitempty" hcl:"rtb"`
	SG        string `json:"sg,omitempty" bson:"sg,omitempty" hcl:"sg"`
	Subnet    string `json:"subnet,omitempty" bson:"subnet,omitempty" hcl:"subnet"`
	VPC       string `json:"vpc,omitempty" bson:"vpc,omitempty" hcl:"vpc"`
	AMI       string `json:"ami,omitempty" bson:"ami,omitempty" hcl:"ami"`
}

func (meta *AwsMeta) BootstrapValid() error {
	if meta.ACL == "" {
		return errors.New("acl is empty or missing")
	}
	if meta.CidrBlock == "" {
		return errors.New("CIDR block is empty or missing")
	}
	if meta.IGW == "" {
		return errors.New("IGW is empty or missing")
	}
	if meta.KeyPair == "" {
		return errors.New("key pair is empty or missing")
	}
	if meta.RTB == "" {
		return errors.New("RTB is empty or missing")
	}
	if meta.SG == "" {
		return errors.New("SG is empty or missing")
	}
	if meta.Subnet == "" {
		return errors.New("subnet is empty or missing")
	}
	if meta.VPC == "" {
		return errors.New("VPC is empty or missing")
	}
	if meta.AMI == "" {
		return errors.New("AMI is empty or missing")
	}
	return nil
}

// Credentials creates new AWS credentials value from the given meta.
func (meta *AwsMeta) Credentials() *credentials.Credentials {
	return credentials.NewStaticCredentials(meta.AccessKey, meta.SecretKey, "")
}

// Options creates new amazon client options.
func (meta *AwsMeta) Options() *amazon.ClientOptions {
	return &amazon.ClientOptions{
		Credentials: meta.Credentials(),
		Region:      meta.Region,
	}
}

func (meta *AwsMeta) session() *session.Session {
	return amazon.NewSession(meta.Options())
}

const arnPrefix = "arn:aws:iam::"

// AccountID parses an AWS arn string to get the Account ID.
func (meta *AwsMeta) AccountID() (string, error) {
	user, err := iam.New(meta.session()).GetUser(nil)
	if err == nil {
		return parseAccountID(aws.StringValue(user.User.Arn))
	}

	for msg := err.Error(); msg != ""; {
		i := strings.Index(msg, arnPrefix)

		if i == -1 {
			break
		}

		msg = msg[i:]

		accountID, e := parseAccountID(msg)
		if e != nil {
			continue
		}

		return accountID, nil
	}

	return "", err
}

// The function assumes arn string comes from an IAM resource, as
// it treats region empty.
//
// For details see:
//
//   http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns
//
// Example arn string: "arn:aws:iam::213456789:user/username"
// Returns: 213456789
func parseAccountID(arn string) (string, error) {
	if !strings.HasPrefix(arn, arnPrefix) {
		return "", fmt.Errorf("invalid ARN: %q", arn)
	}

	accountID := arn[len(arnPrefix):]
	i := strings.IndexRune(accountID, ':')

	if i == -1 {
		return "", fmt.Errorf("invalid ARN: %q", arn)
	}

	accountID = accountID[:i]

	if accountID == "" {
		return "", fmt.Errorf("invalid ARN: %q", arn)
	}

	return accountID, nil
}

func (meta *AwsMeta) ResetBootstrap() {
	meta.ACL = ""
	meta.CidrBlock = ""
	meta.IGW = ""
	meta.KeyPair = ""
	meta.RTB = ""
	meta.SG = ""
	meta.Subnet = ""
	meta.VPC = ""
	meta.AMI = ""
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

// Stack implements the kloud.StackProvider interface.
type Stack struct {
	*provider.BaseStack

	p *stackplan.Planner

	// The following fields are set by buildResources method:
	ids     stackplan.KiteMap
	klients map[string]*stackplan.DialState
	ident   string
	cred    *AwsMeta
}

// Ensure Provider implements the kloud.StackProvider interface.
//
// StackProvider is an interface for team kloud API.
var _ stack.Provider = (*Provider)(nil)

// Stack gives a kloud.Stacker value that implements stack
// methods for the AWS cloud.
func (p *Provider) Stack(ctx context.Context) (stack.Stack, error) {
	bs, err := p.BaseStack(ctx)
	if err != nil {
		return nil, err
	}

	s := &Stack{
		BaseStack: bs,
		p: &stackplan.Planner{
			Provider:     "aws",
			ResourceType: "instance",
		},
	}

	bs.BuildResources = s.buildResources
	bs.WaitResources = s.waitResources
	bs.UpdateResources = s.updateResources

	return s, nil
}

// Meta implements the stack.Provider interface.
func (p *Provider) Meta() interface{} {
	return &AwsMeta{}
}
