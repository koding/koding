package silent

import "koding/klient/machine/mount/notify"

// Builder is a factory for Silent notification objects.
type Builder struct{}

// Build satisfies notify.Builder interface. It produces Silent objects. Build
// options are not used.
func (Builder) Build(_ *notify.BuildOpts) (notify.Notifier, error) {
	return Silent{}, nil
}

// Silent is a notification object that doesn't produce any notifications. This
// means that this type should be used only in tests which don't care about
// file system notifications.
type Silent struct{}

// Close satisfies notify.Notifier interface. It does nothing.
func (Silent) Close() error { return nil }
