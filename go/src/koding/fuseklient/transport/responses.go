package transport

import (
	"encoding/base64"
	"encoding/json"
	"os"
	"time"
)

// ReadDirRes is the response for reading entries in a dir.
type ReadDirRes struct {
	Files []*GetInfoRes `json:"files"`
}

// GetInfoRes is the response for getting info about a single entry.
type GetInfoRes struct {
	Exists   bool        `json:"exists"`
	FullPath string      `json:"fullPath"`
	IsBroken bool        `json:"isBroken"`
	IsDir    bool        `json:"isDir"`
	Mode     os.FileMode `json:"mode"`
	Name     string      `json:"name"`
	Readable bool        `json:"readable"`
	Size     uint64      `json:"size"`
	Time     time.Time   `json:"time"`
	Writable bool        `json:"writable"`
}

// ReadFileRes is the response of reading a single file.
type ReadFileRes struct {
	Content []byte
}

// UnmarshalJSON satisfies the json reader interface. This is required since
// remote returns an map while a struct is more useful here.
func (f *ReadFileRes) UnmarshalJSON(b []byte) error {
	var m map[string]string
	if err := json.Unmarshal(b, &m); err != nil {
		return err
	}

	data, err := base64.StdEncoding.DecodeString(m["content"])
	if err != nil {
		return err
	}

	f.Content = data

	return nil
}

// GetDiskInfoRes is the response of reading mount info of a disk.
type GetDiskInfoRes struct {
	BlockSize   uint32 `json:"blockSize"`
	BlocksTotal uint64 `json:"blocksTotal"`
	BlocksFree  uint64 `json:"blocksFree"`
	BlocksUsed  uint64 `json:"blocksUsed"`
}

// ExecRes is the response of the command that ran.
type ExecRes struct {
	Stdout     string `json:"stdout"`
	Stderr     string `json:"stderr"`
	ExitStatus int    `json:"exitStatus"`
}
