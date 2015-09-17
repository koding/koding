package transport

import (
	"encoding/base64"
	"encoding/json"
	"os"
	"time"
)

type FsReadDirectoryRes struct {
	Files []FsGetInfoRes `json:"files"`
}

type FsGetInfoRes struct {
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

type FsReadFileRes struct {
	Content []byte
}

func (f *FsReadFileRes) UnmarshalJSON(b []byte) error {
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
