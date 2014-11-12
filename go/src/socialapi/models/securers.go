package models

func ChannelSecurer(permissionName string, request *Channel, context *Context) error {
	return nil
}

func MessageSecurer(permissionName string, request *ChannelMessage, context *Context) error {
	return nil
}

func AccountSecurer(permissionName string, request *Account, context *Context) error {
	return nil
}
