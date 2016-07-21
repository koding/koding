package tunnel

import (
	"net"
	"strconv"
	"sync"
	"sync/atomic"

	"github.com/koding/logging"
)

type listener struct {
	net.Listener
	*vaddrOptions

	done int32

	// ips keeps track of registered clients for ip-based routing;
	// when last client is deleted from the ip routing map, we stop
	// listening on connections
	ips map[string]struct{}
}

type vaddrOptions struct {
	connCh chan<- net.Conn
	log    logging.Logger
}

type vaddrStorage struct {
	*vaddrOptions

	listeners map[net.Listener]*listener
	ports     map[int]string    // port-based routing: maps port number to identifier
	ips       map[string]string // ip-based routing: maps ip address to identifier

	mu sync.RWMutex
}

func newVirtualAddrs(opts *vaddrOptions) *vaddrStorage {
	return &vaddrStorage{
		vaddrOptions: opts,
		listeners:    make(map[net.Listener]*listener),
		ports:        make(map[int]string),
		ips:          make(map[string]string),
	}
}

func (l *listener) serve() {
	for {
		conn, err := l.Accept()
		if err != nil {
			l.log.Error("failue listening on %q: %s", l.Addr(), err)
			return
		}

		if atomic.LoadInt32(&l.done) != 0 {
			l.log.Debug("stopped serving %q", l.Addr())
			conn.Close()
			return
		}

		l.connCh <- conn
	}
}

func (l *listener) localAddr() string {
	if addr, ok := l.Addr().(*net.TCPAddr); ok {
		if addr.IP.Equal(net.IPv4zero) {
			return net.JoinHostPort("127.0.0.1", strconv.Itoa(addr.Port))
		}
	}
	return l.Addr().String()
}

func (l *listener) stop() {
	if atomic.CompareAndSwapInt32(&l.done, 0, 1) {
		// stop is called when no more connections should be accepted by
		// the user-provided listener; as we can't simple close the listener
		// to not break the guarantee given by the (*Server).DeleteAddr
		// method, we make a dummy connection to break out of serve loop.
		// It is safe to make a dummy connection, as either the following
		// dial will time out when the listener is busy accepting connections,
		// or will get closed immadiately after idle listeners accepts connection
		// and returns from the serve loop.
		conn, err := net.DialTimeout("tcp", l.localAddr(), defaultTimeout)
		if err == nil {
			conn.Close()
		}
	}
}

func (vaddr *vaddrStorage) Add(l net.Listener, ip net.IP, ident string) {
	vaddr.mu.Lock()
	defer vaddr.mu.Unlock()

	lis, ok := vaddr.listeners[l]
	if !ok {
		lis = vaddr.newListener(l)
		vaddr.listeners[l] = lis
		go lis.serve()
	}

	if ip != nil {
		lis.ips[ip.String()] = struct{}{}
		vaddr.ips[ip.String()] = ident
	} else {
		vaddr.ports[mustPort(l)] = ident
	}
}

func (vaddr *vaddrStorage) Delete(l net.Listener, ip net.IP) {
	vaddr.mu.Lock()
	defer vaddr.mu.Unlock()

	lis, ok := vaddr.listeners[l]
	if !ok {
		return
	}

	var stop bool

	if ip != nil {
		delete(lis.ips, ip.String())
		delete(vaddr.ips, ip.String())

		stop = len(lis.ips) == 0
	} else {
		delete(vaddr.ports, mustPort(l))

		stop = true
	}

	// Only stop listening for connections when listener has clients
	// registered to tunnel the connections to.
	if stop {
		lis.stop()
		delete(vaddr.listeners, l)
	}
}

func (vaddr *vaddrStorage) newListener(l net.Listener) *listener {
	return &listener{
		Listener:     l,
		vaddrOptions: vaddr.vaddrOptions,
		ips:          make(map[string]struct{}),
	}
}

func (vaddr *vaddrStorage) getIdent(conn net.Conn) (string, bool) {
	vaddr.mu.Lock()
	defer vaddr.mu.Unlock()

	ip, port, err := parseHostPort(conn.LocalAddr().String())
	if err != nil {
		vaddr.log.Debug("failed to get identifier for connection %q: %s", conn.LocalAddr(), err)
		return "", false
	}

	// First lookup if there's a ip-based route, then try port-base one.

	if ident, ok := vaddr.ips[ip]; ok {
		return ident, true
	}

	ident, ok := vaddr.ports[port]
	return ident, ok
}

func mustPort(l net.Listener) int {
	_, port, err := parseHostPort(l.Addr().String())
	if err != nil {
		// This can happened when user passed custom type that
		// implements net.Listener, which returns ill-formed
		// net.Addr value.
		panic("ill-formed net.Addr: " + err.Error())
	}

	return port
}
