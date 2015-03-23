// +build !appengine

package maxminddb

import "os"

// Open takes a string path to a MaxMind DB file and returns a Reader
// structure or an error. The database file is opened using a memory map,
// except on Google App Engine where mmap is not supported; there the database
// is loaded into memory. Use the Close method on the Reader object to return
// the resources to the system.
func Open(file string) (*Reader, error) {
	mapFile, err := os.Open(file)
	if err != nil {
		return nil, err
	}
	defer mapFile.Close()

	stats, err := mapFile.Stat()
	if err != nil {
		return nil, err
	}

	fileSize := int(stats.Size())
	mmap, err := mmap(int(mapFile.Fd()), fileSize)
	if err != nil {
		return nil, err
	}

	reader, err := FromBytes(mmap)
	if err != nil {
		munmap(mmap)
		return nil, err
	}

	reader.hasMappedFile = true
	return reader, nil
}

// Close unmaps the database file from virtual memory and returns the
// resources to the system. If called on a Reader opened using FromBytes
// or Open on Google App Engine, this method does nothing.
func (r *Reader) Close() {
	if r.hasMappedFile {
		munmap(r.buffer)
		r.hasMappedFile = false
	}
}
