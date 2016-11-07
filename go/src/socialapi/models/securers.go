package models

func ChannelSecurer(permissionName string, c *Channel, context *Context) error {

	// TODO run this function
	return nil
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

func PrivateMessageSecurer(permissionName string, request *ChannelRequest, context *Context) error {
	return nil
}

func PrivateMessageReadSecurer(permissionName string, context *Context) error {
	return nil
}
