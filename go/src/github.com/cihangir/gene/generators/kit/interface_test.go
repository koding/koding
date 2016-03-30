package kit

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestInterface(t *testing.T) {
	s := &schema.Schema{}
	err := json.Unmarshal([]byte(testdata.TestDataFull), s)

	s = s.Resolve(s)

	sts, err := GenerateInterface(common.NewContext(), s)
	common.TestEquals(t, nil, err)
	common.TestEquals(t, expectedInterface[0], string(sts[0].Content))
}

var expectedInterface = []string{`package account

const ServiceName = "account"

// Account represents a registered User
type AccountService interface {
	Create(ctx context.Context, req *models.Account) (res *models.Account, err error)

	Delete(ctx context.Context, req *models.Account) (res *models.Account, err error)

	One(ctx context.Context, req *models.Account) (res *models.Account, err error)

	Some(ctx context.Context, req *models.Account) (res *[]*models.Account, err error)

	Update(ctx context.Context, req *models.Account) (res *models.Account, err error)
}
`}
