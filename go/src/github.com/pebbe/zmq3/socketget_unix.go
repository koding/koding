// +build !windows

package zmq3

/*
#include <zmq.h>
*/
import "C"

// ZMQ_FD: Retrieve file descriptor associated with the socket
//
// See: http://api.zeromq.org/3-2:zmq-getsockopt#toc23
func (soc *Socket) GetFd() (int, error) {
	return soc.getInt(C.ZMQ_FD)
}
