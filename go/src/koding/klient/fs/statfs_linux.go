package fs

import "syscall"

func Statfs(path string) (*DiskInfo, error) {
	var stfs syscall.Statfs_t

	if err := syscall.Statfs(path, &stfs); err != nil {
		return nil, err
	}

	di := &DiskInfo{
		BlockSize:   uint32(stfs.Bsize),
		BlocksTotal: stfs.Blocks,
		BlocksFree:  stfs.Bfree,
	}
	di.BlocksUsed = di.BlocksTotal - di.BlocksFree

	return di, nil
}
