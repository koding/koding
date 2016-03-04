package testutil

type FakeMountcli struct {
	ReturnMountByPath    string
	ReturnMountByPathErr error
}

func (m *FakeMountcli) FindMountedPathByName(name string) (string, error) {
	return m.ReturnMountByPath, m.ReturnMountByPathErr
}
