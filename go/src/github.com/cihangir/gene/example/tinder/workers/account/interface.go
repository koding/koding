package account

import (
	"github.com/cihangir/gene/example/tinder/models"
	"golang.org/x/net/context"
)

const ServiceName = "account"

// Account represents a registered User
type AccountService interface {
	// ByFacebookIDs fetches multiple Accounts from system by their FacebookIDs
	ByFacebookIDs(ctx context.Context, req *[]string) (res *[]*models.Account, err error)

	// ByIDs fetches multiple Accounts from system by their IDs
	ByIDs(ctx context.Context, req *[]int64) (res *[]*models.Account, err error)

	// Create registers and account in the system by the given data
	Create(ctx context.Context, req *models.Account) (res *models.Account, err error)

	// Delete deletes the account from the system with given account id. Deletes are
	// soft.
	Delete(ctx context.Context, req *int64) (res *models.Account, err error)

	// One fetches an Account from system by its ID
	One(ctx context.Context, req *int64) (res *models.Account, err error)

	// Update updates the account on the system with given account data.
	Update(ctx context.Context, req *models.Account) (res *models.Account, err error)
}
