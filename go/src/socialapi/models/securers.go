package models

import "errors"

func ChannelSecurer(permissionName string, c *Channel, context *Context) error {
	if c.Id == 0 {
		return errors.New("request is not valid")
	}

	var accountId int64
	// if user is logged in, get their account id
	if context.IsLoggedIn() {
		accountId = context.Client.Account.Id
	}

	// to do add caching
	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = accountId
	role, err := cp.FetchRole()
	if err != nil {
		return err
	}

	p := NewPermission()
	p.ChannelId = c.Id
	p.RoleConstant = role

	if err := p.EnsureAllowance(); err != nil {
		return err
	}

	return nil
}

func MessageSecurer(permissionName string, request *ChannelMessage, context *Context) error {
	return nil
}

func AccountSecurer(permissionName string, request *Account, context *Context) error {
	return nil
}
