package awsprovider

import (
	"fmt"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stack"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"golang.org/x/net/context"
)

func init() {
	provider.All["aws"] = func(bp *provider.BaseProvider) stack.Provider {
		return &Provider{
			BaseProvider: bp,
		}
	}
}

type Provider struct {
	*provider.BaseProvider
}

func (p *Provider) Machine(ctx context.Context, id string) (stack.Machine, error) {
	bm, err := p.BaseMachine(ctx, id)
	if err != nil {
		return nil, err
	}

	// TODO(rjeczalik): move decoding provider-specific metadata to BaseMachine.
	var mt Meta
	if err := modelhelper.BsonDecode(bm.Meta, &mt); err != nil {
		return nil, err
	}

	if err := mt.Valid(); err != nil {
		return nil, err
	}

	// TODO(rjeczalik): move decoding provider-specific credential to BaseMachine.
	var cred Cred
	if err := p.FetchCredData(bm, &cred); err != nil {
		return nil, err
	}

	p.Log.Debug("aws credential: %+v", cred)

	if mt.Region != cred.Region {
		return nil, fmt.Errorf("region mismatch: machine is %q, credential is %q", mt.Region, cred.Region)
	}

	opts := &amazon.ClientOptions{
		Credentials: credentials.NewStaticCredentials(cred.AccessKey, cred.SecretKey, ""),
		Region:      cred.Region,
		Log:         bm.Log.New("awsapi"),
	}

	c, err := amazon.NewWithOptions(bm.Meta, opts)
	if err != nil {
		return nil, fmt.Errorf("unable to create AWS client for user: %s", err)
	}

	bm.AWSClient = c

	return &Machine{
		BaseMachine: bm,
		Meta:        &mt,
		Cred:        &cred,
	}, nil
}
