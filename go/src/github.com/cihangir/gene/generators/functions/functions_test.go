package functions

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestFunctions(t *testing.T) {
	s := &schema.Schema{}
	err := json.Unmarshal([]byte(testdata.TestDataFull), s)

	s = s.Resolve(s)

	sts, err := (&Generator{}).Generate(common.NewContext(), s)
	common.TestEquals(t, nil, err)

	for i, s := range sts {
		common.TestEquals(t, expecteds[i], string(s.Content))
	}
}

var expecteds = []string{`package accountapi

// New creates a new local Account handler
func NewAccount() *Account { return &Account{} }

// Account is for holding the api functions
type Account struct{}

func (a *Account) Create(ctx context.Context, req *models.Account, res *models.Account) error {
	return db.MustGetDB(ctx).Create(models.NewAccount(), req, res)
}

func (a *Account) Delete(ctx context.Context, req *models.Account, res *models.Account) error {
	return db.MustGetDB(ctx).Delete(models.NewAccount(), req, res)
}

func (a *Account) One(ctx context.Context, req *models.Account, res *models.Account) error {
	return db.MustGetDB(ctx).One(models.NewAccount(), req, res)
}

func (a *Account) Some(ctx context.Context, req *models.Account, res *[]*models.Account) error {
	return db.MustGetDB(ctx).Some(models.NewAccount(), req, res)
}

func (a *Account) Update(ctx context.Context, req *models.Account, res *models.Account) error {
	return db.MustGetDB(ctx).Update(models.NewAccount(), req, res)
}
`,
	`package accountapi

// New creates a new local Profile handler
func NewProfile() *Profile { return &Profile{} }

// Profile is for holding the api functions
type Profile struct{}

func (p *Profile) Create(ctx context.Context, req *models.Profile, res *models.Profile) error {
	return db.MustGetDB(ctx).Create(models.NewProfile(), req, res)
}

func (p *Profile) Delete(ctx context.Context, req *models.Profile, res *models.Profile) error {
	return db.MustGetDB(ctx).Delete(models.NewProfile(), req, res)
}

func (p *Profile) One(ctx context.Context, req *models.Profile, res *models.Profile) error {
	return db.MustGetDB(ctx).One(models.NewProfile(), req, res)
}

func (p *Profile) Some(ctx context.Context, req *models.Profile, res *[]*models.Profile) error {
	return db.MustGetDB(ctx).Some(models.NewProfile(), req, res)
}

func (p *Profile) Update(ctx context.Context, req *models.Profile, res *models.Profile) error {
	return db.MustGetDB(ctx).Update(models.NewProfile(), req, res)
}
`,
}
