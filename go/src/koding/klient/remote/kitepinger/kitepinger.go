package kitepinger

import (
	"fmt"
	"time"

	"github.com/koding/kite/dnode"
)

var kitePingTimeout = 2 * time.Second

// KiteTransport implements the Kite methods that the KitePinger uses.
type KiteTransport interface {
	TellWithTimeout(string, time.Duration, ...interface{}) (*dnode.Partial, error)
}

// KitePinger implements a Pinger interface ontop of an underlying Kite Transport.
//
// The difference between using a KitePinger along with a PingTracker, compared to
// Kite's normal OnDisconnect/OnConnect methods is the customizable frequency of
// notifications. With PingTracker, we determine if the actual communication with
// the Kite is failing, not the connection itself.
type KitePinger struct {
	// The given transport for this KitePinger. Note that the given kite Client will
	// *not* be dialed by KitePinger, you must Dial before hand. Not dialing will
	// result in failed pings.
	transport KiteTransport
}

func NewKitePinger(t KiteTransport) *KitePinger {
	return &KitePinger{
		transport: t,
	}
}

func (p *KitePinger) Ping() Status {
	// Default to success
	status := Success

	_, err := p.transport.TellWithTimeout("kite.ping", kitePingTimeout)
	// If there is any error getting the response we consider it a failed ping. As such,
	// we set the status to false.
	if err != nil {
		fmt.Println("Ping:", err)
		status = Failure
	}

	return status
}
