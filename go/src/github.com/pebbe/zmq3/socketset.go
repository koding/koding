package zmq3

/*
#include <zmq.h>
#include <stdint.h>
#include <stdlib.h>
*/
import "C"

import (
	"time"
	"unsafe"
)

func (soc *Socket) setString(opt C.int, s string) error {
	cs := C.CString(s)
	defer C.free(unsafe.Pointer(cs))
	if i, err := C.zmq_setsockopt(soc.soc, opt, unsafe.Pointer(cs), C.size_t(len(s))); i != 0 {
		return errget(err)
	}
	return nil
}

func (soc *Socket) setInt(opt C.int, value int) error {
	val := C.int(value)
	if i, err := C.zmq_setsockopt(soc.soc, opt, unsafe.Pointer(&val), C.size_t(unsafe.Sizeof(val))); i != 0 {
		return errget(err)
	}
	return nil
}

func (soc *Socket) setInt64(opt C.int, value int64) error {
	val := C.int64_t(value)
	if i, err := C.zmq_setsockopt(soc.soc, opt, unsafe.Pointer(&val), C.size_t(unsafe.Sizeof(val))); i != 0 {
		return errget(err)
	}
	return nil
}

func (soc *Socket) setUInt64(opt C.int, value uint64) error {
	val := C.uint64_t(value)
	if i, err := C.zmq_setsockopt(soc.soc, opt, unsafe.Pointer(&val), C.size_t(unsafe.Sizeof(val))); i != 0 {
		return errget(err)
	}
	return nil
}

// ZMQ_SNDHWM: Set high water mark for outbound messages
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc3
func (soc *Socket) SetSndhwm(value int) error {
	return soc.setInt(C.ZMQ_SNDHWM, value)
}

// ZMQ_RCVHWM: Set high water mark for inbound messages
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc4
func (soc *Socket) SetRcvhwm(value int) error {
	return soc.setInt(C.ZMQ_RCVHWM, value)
}

// ZMQ_AFFINITY: Set I/O thread affinity
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc5
func (soc *Socket) SetAffinity(value uint64) error {
	return soc.setUInt64(C.ZMQ_AFFINITY, value)
}

// ZMQ_SUBSCRIBE: Establish message filter
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc6
func (soc *Socket) SetSubscribe(filter string) error {
	return soc.setString(C.ZMQ_SUBSCRIBE, filter)
}

// ZMQ_UNSUBSCRIBE: Remove message filter
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc7
func (soc *Socket) SetUnsubscribe(filter string) error {
	return soc.setString(C.ZMQ_UNSUBSCRIBE, filter)
}

// ZMQ_IDENTITY: Set socket identity
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc8
func (soc *Socket) SetIdentity(value string) error {
	return soc.setString(C.ZMQ_IDENTITY, value)
}

// ZMQ_RATE: Set multicast data rate
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc9
func (soc *Socket) SetRate(value int) error {
	return soc.setInt(C.ZMQ_RATE, value)
}

// ZMQ_RECOVERY_IVL: Set multicast recovery interval
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc10
func (soc *Socket) SetRecoveryIvl(value time.Duration) error {
	val := int(value / time.Millisecond)
	return soc.setInt(C.ZMQ_RECOVERY_IVL, val)
}

// ZMQ_SNDBUF: Set kernel transmit buffer size
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc11
func (soc *Socket) SetSndbuf(value int) error {
	return soc.setInt(C.ZMQ_SNDBUF, value)
}

// ZMQ_RCVBUF: Set kernel receive buffer size
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc12
func (soc *Socket) SetRcvbuf(value int) error {
	return soc.setInt(C.ZMQ_RCVBUF, value)
}

// ZMQ_LINGER: Set linger period for socket shutdown
//
// Use -1 for infinite
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc13
func (soc *Socket) SetLinger(value time.Duration) error {
	val := int(value / time.Millisecond)
	if value == -1 {
		val = -1
	}
	return soc.setInt(C.ZMQ_LINGER, val)
}

// ZMQ_RECONNECT_IVL: Set reconnection interval
//
// Use -1 for no reconnection
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc14
func (soc *Socket) SetReconnectIvl(value time.Duration) error {
	val := int(value / time.Millisecond)
	if value == -1 {
		val = -1
	}
	return soc.setInt(C.ZMQ_RECONNECT_IVL, val)
}

// ZMQ_RECONNECT_IVL_MAX: Set maximum reconnection interval
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc15
func (soc *Socket) SetReconnectIvlMax(value time.Duration) error {
	val := int(value / time.Millisecond)
	return soc.setInt(C.ZMQ_RECONNECT_IVL_MAX, val)
}

// ZMQ_BACKLOG: Set maximum length of the queue of outstanding connections
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc16
func (soc *Socket) SetBacklog(value int) error {
	return soc.setInt(C.ZMQ_BACKLOG, value)
}

// ZMQ_MAXMSGSIZE: Maximum acceptable inbound message size
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc17
func (soc *Socket) SetMaxmsgsize(value int64) error {
	return soc.setInt64(C.ZMQ_MAXMSGSIZE, value)
}

// ZMQ_MULTICAST_HOPS: Maximum network hops for multicast packets
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc18
func (soc *Socket) SetMulticastHops(value int) error {
	return soc.setInt(C.ZMQ_MULTICAST_HOPS, value)
}

// ZMQ_RCVTIMEO: Maximum time before a recv operation returns with EAGAIN
//
// Use -1 for infinite
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc19
func (soc *Socket) SetRcvtimeo(value time.Duration) error {
	val := int(value / time.Millisecond)
	if value == -1 {
		val = -1
	}
	return soc.setInt(C.ZMQ_RCVTIMEO, val)
}

// ZMQ_SNDTIMEO: Maximum time before a send operation returns with EAGAIN
//
// Use -1 for infinite
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc20
func (soc *Socket) SetSndtimeo(value time.Duration) error {
	val := int(value / time.Millisecond)
	if value == -1 {
		val = -1
	}
	return soc.setInt(C.ZMQ_SNDTIMEO, val)
}

// ZMQ_IPV4ONLY: Use IPv4-only sockets
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc21
func (soc *Socket) SetIpv4only(value bool) error {
	val := 0
	if value {
		val = 1
	}
	return soc.setInt(C.ZMQ_IPV4ONLY, val)
}

// ZMQ_DELAY_ATTACH_ON_CONNECT: Accept messages only when connections are made
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc22
func (soc *Socket) SetDelayAttachOnConnect(value bool) error {
	val := int(0)
	if value {
		val = 1
	}
	return soc.setInt(C.ZMQ_DELAY_ATTACH_ON_CONNECT, val)
}

// ZMQ_ROUTER_MANDATORY: accept only routable messages on ROUTER sockets
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc23
func (soc *Socket) SetRouterMandatory(value int) error {
	return soc.setInt(C.ZMQ_ROUTER_MANDATORY, value)
}

// ZMQ_XPUB_VERBOSE: provide all subscription messages on XPUB sockets
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc24
func (soc *Socket) SetXpubVerbose(value int) error {
	return soc.setInt(C.ZMQ_XPUB_VERBOSE, value)
}

// ZMQ_TCP_KEEPALIVE: Override SO_KEEPALIVE socket option
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc25
func (soc *Socket) SetTcpKeepalive(value int) error {
	return soc.setInt(C.ZMQ_TCP_KEEPALIVE, value)
}

// ZMQ_TCP_KEEPALIVE_IDLE: Override TCP_KEEPCNT(or TCP_KEEPALIVE on some OS)
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc26
func (soc *Socket) SetTcpKeepaliveIdle(value int) error {
	return soc.setInt(C.ZMQ_TCP_KEEPALIVE_IDLE, value)
}

// ZMQ_TCP_KEEPALIVE_CNT: ZMQ_TCP_KEEPALIVE_CNT: Override TCP_KEEPCNT socket option
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc27
func (soc *Socket) SetTcpKeepaliveCnt(value int) error {
	return soc.setInt(C.ZMQ_TCP_KEEPALIVE_CNT, value)
}

// ZMQ_TCP_KEEPALIVE_INTVL: Override TCP_KEEPINTVL socket option
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc28
func (soc *Socket) SetTcpKeepaliveIntvl(value int) error {
	return soc.setInt(C.ZMQ_TCP_KEEPALIVE_INTVL, value)
}

// ZMQ_TCP_ACCEPT_FILTER: Assign filters to allow new TCP connections
//
// See: http://api.zeromq.org/3-2:zmq-setsockopt#toc29
func (soc *Socket) SetTcpAcceptFilter(filter string) error {
	return soc.setString(C.ZMQ_TCP_ACCEPT_FILTER, filter)
}
