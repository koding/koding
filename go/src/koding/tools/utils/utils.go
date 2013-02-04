package utils

import (
	cryptorand "crypto/rand"
	"encoding/base64"
	"encoding/binary"
	"net"
	"sort"
)

const MaxInt = int(^uint(0) >> 1)

func RandomString() string {
	r := make([]byte, 128/8)
	cryptorand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
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
