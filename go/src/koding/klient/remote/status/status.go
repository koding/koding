package status

import (
	"fmt"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/machine"
	"koding/klient/util"
	"net/http"
	"time"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

const (
	tokenExpiredMessage     = "token is expired"
	tokenNotValidYetMessage = "token is not valid yet"
)

var (
	defaultHTTPClient = &http.Client{
		Timeout: 4 * time.Second,
	}
)

// Used to check the status of a remote machine / kite.
type MachineGetter interface {
	GetMachinesWithoutCache() (machine.Machines, error)
	GetMachine(string) (*machine.Machine, error)
}

// Status deals with checking the status of remote kites, kontrol, and etc.
// Implementing the core logic of Klient's remote.status method.
type Status struct {
	Log logging.Logger

	// Used to fetch machines from a remote.
	MachineGetter MachineGetter

	// Used to curl the machines directly, outside of kite protocol.
	HTTPClient *http.Client
}

func NewStatus(log logging.Logger, mg MachineGetter) *Status {
	return &Status{
		Log:           log.New("status"),
		MachineGetter: mg,
		HTTPClient:    defaultHTTPClient,
	}
}

// handleKiteErr handles a kite transport error, filtering out common connection
// related errors. If the given error is *not* a kiteErr, the normal error is
// returned.
//
// If nil is given as an arg, nil is returned.
func (s *Status) handleKiteErr(err error) error {
	// By checking for nil, we allow usage of this func like:
	// handleKIteErr(Dial()), if desired.
	if err == nil {
		return nil
	}

	kErr, ok := err.(*kite.Error)

	// If we fail to cast the kite error, this is a normal error type. We currently
	// have no cases to handle for that, so return it.
	if !ok {
		return err
	}

	// Authentication errors come from the kite lib, so parse the messages to return
	// easy to decpiher types.
	if kErr.Type == kiteerrortypes.AuthenticationError {
		switch kErr.Message {
		case tokenExpiredMessage:
			return util.NewKiteError(kiteerrortypes.AuthErrTokenIsExpired, err)
		case tokenNotValidYetMessage:
			return util.NewKiteError(kiteerrortypes.AuthErrTokenIsNotValidYet, err)
		}
	}

	// If we get here, the kite error type is not handled. Return the original
	// error.
	return err
}

// KontrolStatus checks the status of our connection to kontrol, returning
// ok or no.
//
// TODO: IMPORTANT: Use a less costly method to determine if Kontrol is connected.
// An ideal method would simply be `ping`, but Kontrol does not currently implement
// ping.
func (s *Status) KontrolStatus() (bool, error) {
	if _, err := s.MachineGetter.GetMachinesWithoutCache(); err != nil {
		return false, fmt.Errorf("Unable to get kontrol connection. err:%s", err)
	}

	return true, nil
}

// MachineStatus dials the given machine name, pings it, and returns ok or not.
// Custom type errors for any problems encountered.
func (s *Status) MachineStatus(name string) (bool, error) {
	machine, err := s.MachineGetter.GetMachine(name)
	if err != nil {
		return false, err
	}

	if machine == nil {
		return false, util.KiteErrorf(
			kiteerrortypes.MachineNotFound, "Machine %q not found", name,
		)
	}

	// Try and ping it directly via http. This lets us
	if _, err := s.HTTPClient.Get(fmt.Sprintf("http://%s:56789/kite", machine.IP)); err != nil {
		return false, util.KiteErrorf(
			kiteerrortypes.MachineUnreachable,
			"Machine unreachable. host:%s, err:%s",
			machine.IP, err,
		)
	}

	if err := machine.Dial(); err != nil {
		return false, s.handleKiteErr(err)
	}

	if err := machine.Ping(); err != nil {
		return false, s.handleKiteErr(err)
	}

	return true, nil
}
