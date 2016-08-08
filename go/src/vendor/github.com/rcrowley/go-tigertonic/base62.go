package tigertonic

import (
	"crypto/rand"
	"math/big"
)

var (
	alphabet string = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	base     *big.Int
)

func RandomBase62Bytes(ii int) []byte {
	buf := make([]byte, ii)
	for i := 0; i < ii; i++ {
		n, err := rand.Int(rand.Reader, base)
		if nil != err {
			panic(err)
		}
		buf[i] = alphabet[n.Int64()]
	}
	return buf
}

func RandomBase62String(ii int) string {
	return string(RandomBase62Bytes(ii))
}

func init() {
	base = big.NewInt(int64(len(alphabet)))
}
