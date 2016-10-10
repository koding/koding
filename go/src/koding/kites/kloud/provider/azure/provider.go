package azure

import (
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stack"

	"github.com/Azure/azure-sdk-for-go/management"
	vm "github.com/Azure/azure-sdk-for-go/management/virtualmachine"
	"golang.org/x/net/context"
)

func init() {
	provider.All["azure"] = func(bp *provider.BaseProvider) stack.Provider {
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

	var mt Meta
	if err := modelhelper.BsonDecode(bm.Meta, &mt); err != nil {
		return nil, err
	}

	if err := mt.Valid(); err != nil {
		return nil, err
	}

	var cred Cred
	if err := p.FetchCredData(bm, &cred); err != nil {
		return nil, err
	}

	c, err := management.ClientFromPublishSettingsDataWithConfig(cred.PublishSettings, cred.SubscriptionID, management.DefaultConfig())
	if err != nil {
		return nil, err
	}

	vmclient := vm.NewClient(c)

	return &Machine{
		BaseMachine:   bm,
		Meta:          &mt,
		Cred:          &cred,
		AzureVMClient: &vmclient,
		AzureClient:   c,
	}, nil
}

func (p *Provider) Cred() interface{} {
	return &Cred{}
}
