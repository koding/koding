package oskite

import "sync/atomic"

type AtomicInt32 int32

func (i *AtomicInt32) Add(n int32) int32 {
	return atomic.AddInt32((*int32)(i), n)
}

func (i *AtomicInt32) Set(n int32) {
	atomic.StoreInt32((*int32)(i), n)
}

func (i *AtomicInt32) Get() int32 {
	return atomic.LoadInt32((*int32)(i))
}

// Atomic Boolean
func (i *AtomicInt32) Closed() bool {
	return atomic.LoadInt32((*int32)(i)) > 0
}

func (i *AtomicInt32) SetClosed() bool {
	return atomic.CompareAndSwapInt32((*int32)(i), 0, 1)
}
