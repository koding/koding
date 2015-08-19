package kodingutils

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
)

// IsKodingOwnedVM return if user is Koding employee.
func IsKodingEmployee(username string) (bool, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return false, err
	}

	for _, flag := range account.GlobalFlags {
		if flag == models.AccountFlagStaff {
			return true, nil
		}
	}

	return false, nil
}

func BanUser(username string, force bool) error {
	return nil
}
