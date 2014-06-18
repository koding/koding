package models

type MetaBits int16

func (m MetaBits) MarkTroll() {
	// set first bit as 1
	m |= 1
}

func (m MetaBits) IsTroll() bool {
	// get first bit
	return (m & 1) == 1
}
