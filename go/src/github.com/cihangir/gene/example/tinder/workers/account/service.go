package account

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

type account struct{}

func NewAccount() AccountService {
	return &account{}
}

// ByFacebookIDs fetches multiple Accounts from system by their FacebookIDs
func (a *account) ByFacebookIDs(ctx context.Context, req *[]string) (*[]*models.Account, error) {
	return nil, nil
}

// ByIDs fetches multiple Accounts from system by their IDs
func (a *account) ByIDs(ctx context.Context, req *[]int64) (*[]*models.Account, error) {
	return nil, nil
}

// Create registers and account in the system by the given data
func (a *account) Create(ctx context.Context, req *models.Account) (*models.Account, error) {
	return nil, nil
}

// Delete deletes the account from the system with given account id. Deletes are
// soft.
func (a *account) Delete(ctx context.Context, req *int64) (*models.Account, error) {
	return nil, nil
}

// One fetches an Account from system by its ID
func (a *account) One(ctx context.Context, req *int64) (*models.Account, error) {
	return nil, nil
}

// Update updates the account on the system with given account data.
func (a *account) Update(ctx context.Context, req *models.Account) (*models.Account, error) {
	return nil, nil
}
