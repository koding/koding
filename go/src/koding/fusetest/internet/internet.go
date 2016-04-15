package internet

import "time"

// ReconnectOpts contains various timing fields, allowing a caller to precisely
// customize the timings of reconnecting.
type ReconnectOpts struct {
	PauseBeforeDisconnect time.Duration
	PauseAfterDisconnect  time.Duration
	PauseBeforeConnect    time.Duration
	PauseAfterConnect     time.Duration
}

func (opts ReconnectOpts) TotalDur() time.Duration {
	dur := opts.PauseBeforeDisconnect
	dur += opts.PauseAfterDisconnect
	dur += opts.PauseBeforeConnect
	dur += opts.PauseAfterConnect
	return dur
}

func ConnectWithOpts(opts ReconnectOpts) error {
	time.Sleep(opts.PauseBeforeConnect)
	err := Connect()
	time.Sleep(opts.PauseAfterConnect)
	return err
}

func DisconnectWithOpts(opts ReconnectOpts) error {
	time.Sleep(opts.PauseBeforeDisconnect)
	err := Disconnect()
	time.Sleep(opts.PauseAfterDisconnect)
	return err
}

func RunWhileDisconnected(opts ReconnectOpts, f func() error) error {
	if err := DisconnectWithOpts(opts); err != nil {
		return err
	}
	defer ConnectWithOpts(opts)

	return f()
}

func ToggleInternet(opts ReconnectOpts) error {
	if err := DisconnectWithOpts(opts); err != nil {
		return err
	}

	return ConnectWithOpts(opts)
}
