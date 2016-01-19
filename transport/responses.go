package transport

import (
	"encoding/base64"
	"encoding/json"
	"os"
	"time"
)

type ReadDirRes struct {
	Files []*GetInfoRes `json:"files"`
}

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

type ReadFileRes struct {
	Content []byte
}

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

type GetDiskInfoRes struct {
	BlockSize   uint32 `json:"blockSize"`
	BlocksTotal uint64 `json:"blocksTotal"`
	BlocksFree  uint64 `json:"blocksFree"`
	BlocksUsed  uint64 `json:"blocksUsed"`
}

type ExecRes struct {
	Stdout     string `json:"stdout"`
	Stderr     string `json:"stderr"`
	ExitStatus int    `json:"exitStatus"`
}
