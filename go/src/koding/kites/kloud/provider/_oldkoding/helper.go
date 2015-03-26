package oldkoding

import (
	"koding/kites/kloud/klient"
	"time"

	"github.com/mitchellh/goamz/ec2"
)

type infoFunc func(format string, formatArgs ...interface{})

// GetInfoLogger returns a customized logger with a another prefix. Usually for
// user based logging.
func (p *Provider) GetCustomLogger(prefix, mode string) infoFunc {
	return func(format string, formatArgs ...interface{}) {
		format = "[%s] " + format
		args := []interface{}{prefix}
		args = append(args, formatArgs...)

		switch mode {
		case "info":
			p.Log.Info(format, args...)
		case "error":
			p.Log.Error(format, args...)
		case "debug":
			p.Log.Debug(format, args...)
		default:
			p.Log.Info(format, args...)
		}
	}
}

// IsKiteReady returns true if Klient is ready and it can receive a ping.
func (p *Provider) IsKlientReady(querystring string) bool {
	klientRef, err := klient.NewWithTimeout(p.Kite, querystring, time.Minute*2)
	if err != nil {
		p.Log.Warning("Connecting to remote Klient instance err: %s", err)
		return false
	}

	defer klientRef.Close()
	p.Log.Debug("Sending a ping message")
	if err := klientRef.Ping(); err != nil {
		p.Log.Debug("Sending a ping message err:", err)
		return false
	}

	return true
}

func isCapacityError(err error) bool {
	ec2Error, ok := err.(*ec2.Error)
	if !ok {
		return false // return back if it's not an ec2.Error type
	}

	fallbackErrors := []string{
		"InsufficientInstanceCapacity",
		"InstanceLimitExceeded",
	}

	// check wether the incoming error code is one of the fallback
	// errors
	for _, fbErr := range fallbackErrors {
		if ec2Error.Code == fbErr {
			return true
		}
	}

	// return for non fallback errors, because we can't do much
	// here and probably it's need a more tailored solution
	return false
}

func isAddressNotFoundError(err error) bool {
	ec2Error, ok := err.(*ec2.Error)
	if !ok {
		return false
	}

	return ec2Error.Code == "InvalidAddress.NotFound"
}
