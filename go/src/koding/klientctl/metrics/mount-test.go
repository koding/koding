package metrics

import "time"

type MountTest struct {
	Path     string
	Interval time.Duration
}

func NewMountTest(path string) *MountTest {
	return &MountTest{
		Path:     path,
		Interval: DefaultInterval,
	}
}

func (m *MountTest) Run() error {
	return nil
}
