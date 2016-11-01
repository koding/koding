package models

const (
	Troll MetaBits = 1 << iota

	// all other bits will be up here

	// safe should be the last one assigned as 0
	Safe MetaBits = 0
)

type MetaBits int16

func (m *MetaBits) Mark(data MetaBits) {
	// bitwise OR
	*m = *m | data
}

func (m *MetaBits) UnMark(data MetaBits) {
	// bit clear (AND NOT)
	*m = *m &^ data
}

func (m MetaBits) Is(data MetaBits) bool {
	return (m & data) == data
}
