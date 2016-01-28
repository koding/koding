package transport

import "os"

// RemoteOrCacheTransport is an implementation of Transport that directs methods
// to the transports in order depending on operation. All write operations are
// first sent to RemoteTransport, while read operations are first sent to
// CacheTransport. Currently we don't cascade requests to transports.
//
// The ordering of transports are so the disk cache doesn't get stale in case of
// connection disruptions. Imagine connection to remote is disconnected, but
// operations continue to happen, this would lead to disk cache become out of
// sync with remote. To prevent this from happening, it sends all write
// operations to remote first.
type RemoteOrCacheTransport struct {
	RemoteTransport Transport
	CacheTransport  Transport
}

//// RemoteOrCacheTransport is an initializer for RemoteOrCacheTransport.
//func NewRemoteOrCacheTransport(rt, ct Transport) *RemoteOrCacheTransport {
//  return &RemoteOrCacheTransport{
//    RemoteTransport: rt,
//    CacheTransport: ct,
//  }
//}

// CreateDir is sent to RemoteTransport only.
func (o *RemoteOrCacheTransport) CreateDir(path string, mode os.FileMode) error {
	return o.RemoteTransport.CreateDir(path, mode)
}

// ReadDir is sent to CacheTransport only.
func (o *RemoteOrCacheTransport) ReadDir(path string, r bool) (*ReadDirRes, error) {
	return o.CacheTransport.ReadDir(path, r)
}

// Rename is sent to RemoteTransport only.
func (o *RemoteOrCacheTransport) Rename(oldName, newName string) error {
	return o.RemoteTransport.Rename(oldName, newName)
}

// Remove is sent to RemoteTransport only.
func (o *RemoteOrCacheTransport) Remove(path string) error {
	return o.RemoteTransport.Remove(path)
}

// ReadFile is sent to CacheTransport only.
func (o *RemoteOrCacheTransport) ReadFile(path string) (*ReadFileRes, error) {
	return o.CacheTransport.ReadFile(path)
}

// WriteFile is sent to RemoteTransport only.
func (o *RemoteOrCacheTransport) WriteFile(path string, data []byte) error {
	return o.RemoteTransport.WriteFile(path, data)
}

// Exec is sent to RemoteTransport only.
func (o *RemoteOrCacheTransport) Exec(cmd string) (*ExecRes, error) {
	return o.RemoteTransport.Exec(cmd)
}

// GetDiskInfo is sent to CacheTransport only.
func (o *RemoteOrCacheTransport) GetDiskInfo(path string) (*GetDiskInfoRes, error) {
	return o.CacheTransport.GetDiskInfo(path)
}

// GetInfo is sent to CacheTransport only.
func (o *RemoteOrCacheTransport) GetInfo(path string) (*GetInfoRes, error) {
	return o.CacheTransport.GetInfo(path)
}
