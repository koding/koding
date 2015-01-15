package main

var (
	ExemptKey = "exempt"

	QueueKey     = "queue"
	GetQueueKey  = QueueKey + ":get"
	StopQueuKey  = QueueKey + ":stop"
	BLockQueuKey = QueueKey + ":block"

	StopLimitKey  = "stoplimit"
	BlockLimitKey = "blocklimit"
)
