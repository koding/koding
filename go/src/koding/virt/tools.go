package virt

import (
	"bufio"
	"io"
	"strconv"
)

func atEndOfFile(r *bufio.Reader) bool {
	_, err := r.ReadByte()
	if err != nil {
		if err == io.EOF {
			return true
		}
		panic(err)
	}
	r.UnreadByte()
	return false
}

func tryReadByte(r *bufio.Reader, b byte) bool {
	c, err := r.ReadByte()
	if err != nil {
		panic(err)
	}

	if c == b {
		return true
	}
	r.UnreadByte()
	return false
}

func readUntil(r *bufio.Reader, delim byte) string {
	line, err := r.ReadString(delim)
	if err != nil {
		panic(err)
	}
	return line[:len(line)-1]
}

func atoi(str string) int {
	i, err := strconv.Atoi(str)
	if err != nil {
		panic(err)
	}
	return i
}

func itoa(i int) string {
	return strconv.Itoa(i)
}
