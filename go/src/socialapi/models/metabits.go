package models

const (
	Safe  = 0
	Troll = 1 << iota
)

type MetaBits int16

// IsSafe checks for data against if it is showable to the user
func (m MetaBits) IsSafe() bool {
	return (m == 0)
}

func (m *MetaBits) MarkTroll() {
	// set first bit as 1
	*m = *m | Troll
}

func (m MetaBits) IsTroll() bool {
	// get first bit
	return (m & Troll) == Troll
}
