package transport

import "os"

// OnionTransport is an implementation of Transport that directs methods to the
// transports in order depending on operation. All write operations are first
// sent to KlientTransport, while read operations are first sent to
// DiskTransport. Currently we don't cascade requests to transports.
//
// The ordering of transports are so the disk cache doesn't get stale in case of
// connection disruptions. Imagine connection to remote is disconnected, but
// operations continue to happen, this would lead to disk cache become out of
// sync with remote. To prevent this from happening, it sends all write
// operations to remote first.
type OnionTransport struct {
	DiskTransport   Transport
	KlientTransport Transport
}

// NewOnionTransport is an initializer for OnionTransport.
func NewOnionTransport(dt, kt Transport) *OnionTransport {
	return &OnionTransport{
		DiskTransport:   dt,
		KlientTransport: kt,
	}
}

// CreateDir is sent to KlientTransport only.
func (o *OnionTransport) CreateDir(path string, mode os.FileMode) error {
	return o.KlientTransport.CreateDir(path, mode)
}

// ReadDir is sent to DiskTransport only.
func (o *OnionTransport) ReadDir(path string, r bool) (*ReadDirRes, error) {
	return o.DiskTransport.ReadDir(path, r)
}

// Rename is sent to KlientTransport only.
func (o *OnionTransport) Rename(oldName, newName string) error {
	return o.KlientTransport.Rename(oldName, newName)
}

// Remove is sent to KlientTransport only.
func (o *OnionTransport) Remove(path string) error {
	return o.KlientTransport.Remove(path)
}

// ReadFile is sent to DiskTransport only.
func (o *OnionTransport) ReadFile(path string) (*ReadFileRes, error) {
	return o.DiskTransport.ReadFile(path)
}

// WriteFile is sent to KlientTransport only.
func (o *OnionTransport) WriteFile(path string, data []byte) error {
	return o.KlientTransport.WriteFile(path, data)
}

// Exec is sent to KlientTransport only.
func (o *OnionTransport) Exec(cmd string) (*ExecRes, error) {
	return o.KlientTransport.Exec(cmd)
}

// GetDiskInfo is sent to DiskTransport only.
func (o *OnionTransport) GetDiskInfo(path string) (*GetDiskInfoRes, error) {
	return o.DiskTransport.GetDiskInfo(path)
}

// GetInfo is sent to DiskTransport only.
func (o *OnionTransport) GetInfo(path string) (*GetInfoRes, error) {
	return o.DiskTransport.GetInfo(path)
}
