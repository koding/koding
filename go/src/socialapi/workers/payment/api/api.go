package api

import (
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

	return nil
}
