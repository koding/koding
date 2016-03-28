package metrics

import (
	"errors"
	"io/ioutil"
	"os"
	"path/filepath"
)

var (
	DefaultFileName = ".kd"
	DefaultFileText = []byte("this is a test file...please ignore")

	ErrDiffContent = errors.New("file content is not what was expected")
)

type MountStatus struct {
	MountPath string
	FileName  string
	FileText  []byte
}

func NewDefaultMountStatus(p string) *MountStatus {
	return &MountStatus{
		MountPath: p,
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

func (m *MountStatus) Remove() error {
	return os.Remove(m.filepath())
}

func (m *MountStatus) filepath() string {
	return filepath.Join(m.MountPath, m.FileName)
}
