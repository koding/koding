package aws

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/iam"
)

const arnPrefix = "arn:aws:iam::"

// Provider is AWS kloud provider.
var Provider = &provider.Provider{
	Name:         "aws",
	ResourceName: "instance",
	Machine:      newMachine,
	Stack:        newStack,
	Schema: &provider.Schema{
		NewCredential: newCredential,
		NewBootstrap:  newBootstrap,
		NewMetadata:   newMetadata,
	},
}

func init() {
	provider.Register(Provider)
}

func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	m := &Machine{BaseMachine: bm}
	cred := m.Cred()

	opts := cred.Options()
	opts.Log = m.Log.New("awsapi")
	opts.NoZones = true

	c, err := amazon.NewWithOptions(m.Meta, opts)
	if err != nil {
		return nil, fmt.Errorf("unable to create AWS client for user %q: %s", m.Username(), err)
	}

	m.AWSClient = c

	return m, nil
}

func newStack(bs *provider.BaseStack) (provider.Stack, error) {
	return &Stack{BaseStack: bs}, nil
}

func newCredential() interface{} {
	return &Cred{}
}

func newBootstrap() interface{} {
	return &Bootstrap{}
}

func newMetadata(m *stack.Machine) interface{} {
	if m == nil {
		return &Meta{}
	}

	meta := &Meta{
		InstanceID:       m.Attributes["id"],
		AvailabilityZone: m.Attributes["availability_zone"],
		PlacementGroup:   m.Attributes["placement_group"],
	}

	if n, err := strconv.Atoi(m.Attributes["root_block_device.0.volume_size"]); err == nil {
		meta.StorageSize = n
	}

	if cred, ok := m.Credential.Credential.(*Cred); ok {
		meta.Region = string(cred.Region)
	}

	return meta
}

// Cred represents jCredentialDatas.meta for "aws" provider.
type Cred struct {
	AccessKey string `json:"access_key" bson:"access_key" hcl:"access_key" kloud:"Access Key ID,secret"`
	SecretKey string `json:"secret_key" bson:"secret_key" hcl:"secret_key" kloud:"Secret Access Key,secret"`
	Region    Region `json:"region" bson:"region" hcl:"region" kloud:"Region"`
}

var _ stack.Validator = (*Cred)(nil)

type Bootstrap struct {
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

var _ stack.Validator = (*Bootstrap)(nil)

func (b *Bootstrap) Valid() error {
	if b.ACL == "" {
		return errors.New(`bootstrap value for "acl" is empty`)
	}
	if b.CidrBlock == "" {
		return errors.New(`bootstrap value for "cidr_block" is empty`)
	}
	if b.IGW == "" {
		return errors.New(`bootstrap value for "igw" is empty`)
	}
	if b.KeyPair == "" {
		return errors.New(`bootstrap value for "key_pair" is empty`)
	}
	if b.RTB == "" {
		return errors.New(`bootstrap value for "rtb" is empty`)
	}
	if b.SG == "" {
		return errors.New(`bootstrap value for "sg" is empty`)
	}
	if b.Subnet == "" {
		return errors.New(`bootstrap value for "subnet" is empty`)
	}
	if b.VPC == "" {
		return errors.New(`bootstrap value for "vpc" is empty`)
	}
	if b.AMI == "" {
		return errors.New(`bootstrap value for "ami" is empty`)
	}
	return nil
}

// Credentials creates new AWS credentials value from the given meta.
func (c *Cred) Credentials() *credentials.Credentials {
	return credentials.NewStaticCredentials(c.AccessKey, c.SecretKey, "")
}

// Options creates new amazon client options.
func (c *Cred) Options() *amazon.ClientOptions {
	return &amazon.ClientOptions{
		Credentials: c.Credentials(),
		Region:      string(c.Region),
	}
}

func (c *Cred) session() *session.Session {
	return amazon.NewSession(c.Options())
}

// AccountID parses an AWS arn string to get the Account ID.
func (c *Cred) AccountID() (string, error) {
	user, err := iam.New(c.session()).GetUser(nil)
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

var (
	reAccessKey = regexp.MustCompile("AKIA[0-9A-Z]{16}")
	reSecretKey = regexp.MustCompile("[0-9a-zA-Z/+]{40}")
)

// Valid implements the kloud.Validator interface.
func (meta *Cred) Valid() error {
	if meta.Region == "" {
		return errors.New("aws: region is empty")
	}
	if meta.AccessKey == "" {
		return errors.New("aws: access key is empty")
	}
	if meta.SecretKey == "" {
		return errors.New("aws: secret key is empty")
	}
	if !reAccessKey.MatchString(meta.AccessKey) {
		return errors.New("aws: access key is invalid")
	}
	if !reSecretKey.MatchString(meta.SecretKey) {
		return errors.New("aws: secret key is invalid")
	}
	return nil
}

var Regions = []stack.Enum{
	{Title: "US East (N. Virginia) (us-east-1)", Value: "us-east-1"},
	{Title: "US West (Oregon) (us-west-2)", Value: "us-west-2"},
	{Title: "US West (N. California) (us-west-1)", Value: "us-west-1"},
	{Title: "EU (Ireland) (eu-west-1)", Value: "eu-west-1"},
	{Title: "EU (Frankfurt) (eu-central-1)", Value: "eu-central-1"},
	{Title: "Asia Pacific (Singapore) (ap-southeast-1)", Value: "ap-southeast-1"},
	{Title: "Asia Pacific (Sydney) (ap-southeast-2)", Value: "ap-southeast-2"},
	{Title: "Asia Pacific (Tokyo) (ap-northeast-1)", Value: "ap-northeast-1"},
	{Title: "South America (Sao Paulo) (sa-east-1)", Value: "sa-east-1"},
}

type Region string

var _ stack.Enumer = Region("")

func (Region) Enums() []stack.Enum {
	return Regions
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
