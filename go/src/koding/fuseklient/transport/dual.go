package transport

import "os"

// DualTransport is an implementation of Transport that directs methods to the
// transports in order depending on operation. All write operations are first
// sent to RemoteTransport, while read operations are first sent to
// CacheTransport. Currently we don't cascade requests to transports.
//
// The ordering of transports are so the disk cache doesn't get stale in case of
// connection disruptions. Imagine connection to remote is disconnected, but
// operations continue to happen, this would lead to disk cache become out of
// sync with remote. To prevent this from happening, it sends all write
// operations to remote first.
type DualTransport struct {
	RemoteTransport Transport
	CacheTransport  Transport
}

// NewDualTransport is an initializer for DualTransport.
func NewDualTransport(rt *RemoteTransport, dt *DiskTransport) *DualTransport {
	// DiskTransport does not ignore any dirs, if RemoteTransport ignores some
	// dirs it'll lead to state mismatch; hence don't ignore any dirs
	rt.SetIgnoreDirs(nil)

	return &DualTransport{
		RemoteTransport: rt,
		CacheTransport:  dt,
	}
}

// CreateDir is sent to RemoteTransport, then CacheTransport.
func (d *DualTransport) CreateDir(path string, mode os.FileMode) error {
	if err := d.RemoteTransport.CreateDir(path, mode); err != nil {
		return err
	}

	return d.CacheTransport.CreateDir(path, mode)
}

// ReadDir is sent to CacheTransport only.
func (d *DualTransport) ReadDir(path string, r bool) (*ReadDirRes, error) {
	return d.CacheTransport.ReadDir(path, r)
}

// Rename is sent to RemoteTransport, then CacheTransport.
func (d *DualTransport) Rename(oldName, newName string) error {
	if err := d.RemoteTransport.Rename(oldName, newName); err != nil {
		return err
	}

	return d.CacheTransport.Rename(oldName, newName)
}

// Remove is sent to RemoteTransport, then CacheTransport.
func (d *DualTransport) Remove(path string) error {
	if err := d.RemoteTransport.Remove(path); err != nil {
		return err
	}

	return d.CacheTransport.Remove(path)
}

// ReadFile is sent to CacheTransport only.
func (d *DualTransport) ReadFile(path string) (*ReadFileRes, error) {
	return d.CacheTransport.ReadFile(path)
}

// ReadFileAt is sent to CacheTransport only.
func (d *DualTransport) ReadFileAt(path string, offset, blockSize int64) (*ReadFileRes, error) {
	return d.CacheTransport.ReadFileAt(path, offset, blockSize)
}

// WriteFile is sent to RemoteTransport, then CacheTransport.
func (d *DualTransport) WriteFile(path string, data []byte) error {
	if err := d.RemoteTransport.WriteFile(path, data); err != nil {
		return err
	}

	return d.CacheTransport.WriteFile(path, data)
}

// Exec is sent to RemoteTransport only.
func (d *DualTransport) Exec(cmd string) (*ExecRes, error) {
	return d.RemoteTransport.Exec(cmd)
}

// GetDiskInfo is sent to CacheTransport only.
func (d *DualTransport) GetDiskInfo(path string) (*GetDiskInfoRes, error) {
	return d.CacheTransport.GetDiskInfo(path)
}

// GetInfo is sent to CacheTransport only.
func (d *DualTransport) GetInfo(path string) (*GetInfoRes, error) {
	return d.CacheTransport.GetInfo(path)
}
