package api

import (
	"errors"
	"koding/db/mongodb/modelhelper"

	"socialapi/models"
)

func checkContext(c *models.Context) error {
	if !c.IsLoggedIn() {
		return models.ErrNotLoggedIn
	}

	isAdmin, err := modelhelper.IsAdmin(c.Client.Account.Nick, c.GroupName)
	if err != nil {
		return err
	}

	if !isAdmin {
		return models.ErrAccessDenied
	}

	u, err := modelhelper.GetUser(c.Client.Account.Nick)
	if err != nil {
		return err
	}

	if u.Status != "confirmed" {
		return errors.New("user should confirm email")
	}

	return nil
}
