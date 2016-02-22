package main

var (
	ExemptKey     = "exempt"
	QueueKey      = "queue"
	GetKey        = "get"
	StopLimitKey  = "stop"
	BlockLimitKey = "block"
)

func getQueueKey(s string) string {
	return QueueKey + ":" + s
}
