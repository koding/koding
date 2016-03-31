package kit

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestServiceCreation(t *testing.T) {
	s := &schema.Schema{}
	err := json.Unmarshal([]byte(testdata.TestDataFull), s)

	s = s.Resolve(s)

	sts, err := GenerateService(common.NewContext(), s)
	common.TestEquals(t, nil, err)
	common.TestEquals(t, serviceExpecteds[0], string(sts[0].Content))
}

var serviceExpecteds = []string{`package account

type account struct{}

func NewAccount() AccountService {
	return &account{}
}

func (a *account) Create(ctx context.Context, req *models.Account) (*models.Account, error) {
	return nil, nil
}
func (a *account) Delete(ctx context.Context, req *models.Account) (*models.Account, error) {
	return nil, nil
}
func (a *account) One(ctx context.Context, req *models.Account) (*models.Account, error) {
	return nil, nil
}
func (a *account) Some(ctx context.Context, req *models.Account) (*[]*models.Account, error) {
	return nil, nil
}
func (a *account) Update(ctx context.Context, req *models.Account) (*models.Account, error) {
	return nil, nil
}
`}
