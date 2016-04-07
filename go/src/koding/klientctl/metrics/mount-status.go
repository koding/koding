package metrics

import (
	"errors"
	"io/ioutil"
	"path/filepath"
)

var (
	DefaultFileName = ".kd"
	DefaultFileText = []byte("This is a test file for checking mount status. please don't remove.")

	ErrDiffContent = errors.New("file content is not what was expected")
)

type MountStatus struct {
	MountPath string
	FileName  string
	FileText  []byte
}

func NewDefaultMountStatus(path string) *MountStatus {
	return &MountStatus{
		MountPath: path,
		FileName:  DefaultFileName,
		FileText:  DefaultFileText,
	}
}

func (m *MountStatus) Write() error {
	return ioutil.WriteFile(m.filepath(), m.FileText, 0644)
}

func (m *MountStatus) CheckContents() error {
	text, err := ioutil.ReadFile(m.filepath())
	if err != nil {
		return err
	}

	if string(text) != string(m.FileText) {
		return ErrDiffContent
	}

	return nil
}

func (m *MountStatus) filepath() string {
	return filepath.Join(m.MountPath, m.FileName)
}
