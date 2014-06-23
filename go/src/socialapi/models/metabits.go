package models

const (
	Troll = 1 << iota
)

type MetaBits int16

func (m MetaBits) IsSafe() bool {
	return (m == 0)
}

func (m MetaBits) MarkTroll() {
	// set first bit as 1
	m |= Troll
}

func (m MetaBits) IsTroll() bool {
	// get first bit
	return (m & Troll) == 1
}
