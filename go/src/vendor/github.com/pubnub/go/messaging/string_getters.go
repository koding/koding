package messaging

var responseStatusName = map[responseStatus]string{
	responseAlreadySubscribed:  "already subscribed",
	responseNotSubscribed:      "not subscribed",
	responseInternetConnIssues: "disconnected due to internet connection issues, trying to reconnect.",
	responseAbortMaxRetry:      "aborted due to max retry limit",
	responseTimedOut:           "timed out.",
}

func (r responseStatus) String() string {
	return responseStatusName[r]
}

var connectionActionName = map[connectionAction]string{
	connectionConnected:    "connect",
	connectionUnsubscribed: "unsubscrib",
	connectionReconnected:  "reconnect",
}

func (c connectionAction) String() string {
	return connectionActionName[c]
}

var responseTypeName = map[responseType]string{
	channelResponse:      "channel",
	channelGroupResponse: "channel group",
	wildcardResponse:     "wildcard channel",
}

func (r responseType) String() string {
	return responseTypeName[r]
}

var subscribeLoopActionName = map[subscribeLoopAction]string{
	subscribeLoopStart:     "start",
	subscribeLoopRestart:   "restart",
	subscribeLoopDoNothing: "do nothing",
}

func (s subscribeLoopAction) String() string {
	return subscribeLoopActionName[s]
}
