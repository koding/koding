package flagext

import "testing"
import "github.com/stretchr/testify/assert"

func TestMarshalBytesize(t *testing.T) {
	v, err := ByteSize(1024).MarshalFlag()
	if assert.NoError(t, err) {
		assert.Equal(t, "1.024 kB", v)
	}
}

func TestUnmarshalBytesize(t *testing.T) {
	var b ByteSize
	err := b.UnmarshalFlag("notASize")
	assert.Error(t, err)

	err = b.UnmarshalFlag("1MB")
	if assert.NoError(t, err) {
		assert.Equal(t, ByteSize(1000000), b)
	}
}
