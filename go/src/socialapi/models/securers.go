package models

func ChannelSecurer(permissionName string, c *Channel, context *Context) error {

	// TODO run this function
	return nil

	// var accountId int64
	// // if user is logged in, get their account id
	// if context.IsLoggedIn() {
	// 	accountId = context.Client.Account.Id
	// }

	// // to do add caching
	// cp := NewChannelParticipant()
	// cp.ChannelId = c.Id
	// cp.AccountId = accountId
	// role, err := cp.FetchRole()
	// if err != nil {
	// 	return err
	// }

	// p := NewPermission()
	// p.ChannelId = c.Id
	// p.RoleConstant = role

	// // check if the user is allowed to take action
	// if err := p.EnsureAllowance(); err != nil {
	// 	return err
	// }

	// return nil
}

func ChannelReadSecurer(permissionName string, context *Context) error {
	return nil
}

func MessageSecurer(permissionName string, request *ChannelMessage, context *Context) error {
	return nil
}

func MessageReadSecurer(permissionName string, context *Context) error {
	return nil
}

func MessageDeleteSecurer(permissionName string, context *Context) error {
	return nil
}

func AccountSecurer(permissionName string, request *Account, context *Context) error {
	return nil
}

func AccountReadSecurer(permissionName string, context *Context) error {
	return nil
}

func InteractionSecurer(permissionName string, request *Interaction, context *Context) error {
	return nil
}

func InteractionReadSecurer(permissionName string, context *Context) error {
	return nil
}

func ParticipantMultiSecurer(permissionName string, request []*ChannelParticipant, context *Context) error {
	return nil
}

func ParticipantSecurer(permissionName string, request *ChannelParticipant, context *Context) error {
	return nil
}

func ParticipantReadSecurer(permissionName string, context *Context) error {
	return nil
}

func MessageListSecurer(permissionName string, request *ChannelMessageList, context *Context) error {
	return nil
}

func MessageListReadSecurer(permissionName string, context *Context) error {
	return nil
}

func PinnedActivitySecurer(permissionName string, request *PinRequest, context *Context) error {
	return nil
}

func PinnedActivityReadSecurer(permissionName string, context *Context) error {
	return nil
}

func PrivateMessageSecurer(permissionName string, request *PrivateChannelRequest, context *Context) error {
	return nil
}

func PrivateMessageReadSecurer(permissionName string, context *Context) error {
	return nil
}
