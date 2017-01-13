package utils

import (
	"bytes"
	cryptorand "crypto/rand"
	"encoding/binary"
	"encoding/hex"
	"io"
	"net"
	"sort"
	"unicode/utf8"
)

const MaxInt = int(^uint(0) >> 1)

const RandomStringLength = 24 // 144 bit base64 encoded

func RandomString() string {
	return StringN(RandomStringLength)
}

func StringN(n int) string {
	p := make([]byte, n/2+1)
	cryptorand.Read(p)
	return hex.EncodeToString(p)[:n]
}

var (
	upperChars   = []byte("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	lowerChars   = []byte("abcdefghijklmnopqrstuvwxyz")
	numberChars  = []byte("0123456789")
	specialChars = []byte("!@#$%^&*()-_=+,.?/:;{}[]`~")
	allChars     = append(upperChars, append(lowerChars, append(numberChars, specialChars...)...)...)
)

// Pwgen generates n-long random string that matches
// most password complexity requirements.
func Pwgen(n int) string {
	if n < 4 {
		return PwgenChars(n, allChars)
	}

	var buf bytes.Buffer

	buf.WriteString(PwgenChars(n/4, upperChars))
	buf.WriteString(PwgenChars(n/4, lowerChars))
	buf.WriteString(PwgenChars(n/4, numberChars))
	buf.WriteString(PwgenChars(n/4, specialChars))

	buf.WriteString(PwgenChars(n-(n/4*4), allChars))

	return buf.String()
}

// PwgenChars generates n-long random string
// out of chars.
//
// It returns empty string if n <= 0.
//
// NOTE(rjeczalik): adapted version basing original codes from:
//
//   https://git.io/vX5u0.
//
func PwgenChars(n int, chars []byte) string {
	if n <= 0 {
		return ""
	}

	pw := make([]byte, 0, n)
	p := make([]byte, n+(n/4))
	clen := byte(len(chars))
	maxrb := byte(256 - (256 % len(chars)))

	for {
		if _, err := io.ReadFull(cryptorand.Reader, p); err != nil {
			return string(pw)
		}

		for _, c := range p {
			if c >= maxrb {
				continue
			}

			pw = append(pw, chars[c%clen])

			if len(pw) == n {
				return string(pw)
			}
		}
	}
}

func NewIntPool(offset int, alreadyTaken []int) (<-chan int, chan<- int) {
	fetchChan := make(chan int)
	releaseChan := make(chan int)
	go func() {
		tail := offset
		unused := make([]int, 0)
		sort.Ints(alreadyTaken)
		for _, v := range alreadyTaken {
			for tail <= v {
				if tail != v {
					unused = append(unused, tail)
				}
				tail += 1
			}
		}
		for {
			if len(unused) == 0 {
				unused = append(unused, tail)
				tail += 1
			}
			select {
			case fetchChan <- unused[len(unused)-1]:
				unused = unused[:len(unused)-1]
			case i := <-releaseChan:
				unused = append(unused, i)
			}
		}
	}()
	return fetchChan, releaseChan
}

func IntToIP(v int) net.IP {
	ip := net.IPv4(0, 0, 0, 0)
	binary.BigEndian.PutUint32(ip[12:16], uint32(v))
	return ip
}

func IPToInt(ip net.IP) int {
	return int(binary.BigEndian.Uint32(ip[12:16]))
}

func FilterInvalidUTF8(buf []byte) []byte {
	i := 0
	j := 0
	for {
		r, l := utf8.DecodeRune(buf[i:])
		if l == 0 {
			break
		}
		if r < 0xD800 {
			if i != j {
				copy(buf[j:], buf[i:i+l])
			}
			j += l
		}
		i += l
	}
	return buf[:j]
}
