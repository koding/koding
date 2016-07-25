package main

import (
	"io"
	"os"
)

type Rot13 struct{ w io.Writer }

func (w Rot13) Write(b []byte) (int, error) {
	var buf [1024]byte
	n := copy(buf[:], b)
	for i, b := range buf[:n] {
		switch {
		case 'a' <= b && b <= 'm', 'A' <= b && b <= 'M':
			buf[i] = b + 13
		case 'n' <= b && b <= 'z', 'N' <= b && b <= 'Z':
			buf[i] = b - 13
		}
	}
	return w.w.Write(buf[:n])
}

func main() {
	io.Copy(Rot13{os.Stdout}, os.Stdin)
}
