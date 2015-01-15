package main

var (
	ExemptKey     = "exempt"
	QueueKey      = "queue"
	GetKey        = "stop"
	StopLimitKey  = "stop"
	BlockLimitKey = "block"
)

func getQueueKey(s string) string {
	return QueueKey + ":" + s
}
