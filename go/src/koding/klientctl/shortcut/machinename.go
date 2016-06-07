package shortcut

import (
	"errors"
	"koding/klientctl/list"
)

var ErrMachineNotFound = errors.New("Machine not found.")

type Klient interface {
	RemoteList() (list.KiteInfos, error)
}

// MachineShortcut implements
type MachineShortcut struct {
	Klient Klient
}

func NewMachineShortcut(k Klient) *MachineShortcut {
	return &MachineShortcut{
		Klient: k,
	}
}

func (s *MachineShortcut) GetNameFromShortcut(shortcut string) (string, error) {
	info, err := s.GetMachineInfoFromShortcut(shortcut)
	// Zero value will be returned if err
	return info.VMName, err
}

func (s *MachineShortcut) GetMachineInfoFromShortcut(shortcut string) (list.KiteInfo, error) {
	infos, err := s.Klient.RemoteList()
	if err != nil {
		return list.KiteInfo{}, err
	}

	// Find the machine by a name, even if partial.
	info, ok := infos.FindFromName(shortcut)
	if !ok {
		return list.KiteInfo{}, ErrMachineNotFound
	}

	return info, nil
}
