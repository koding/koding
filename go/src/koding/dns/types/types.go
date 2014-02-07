/* Various types and constants for a DNS server.
   Mostly taken directly from RFC 1035.
   Various functions for things like encoding.
   TODO: replace them by things from package net/?
   <http://golang.org/src/pkg/net/dnsmsg.go> */

package types

import (
	"encoding/binary"
	"fmt"
	"net"
	"strings"
)

// This type is used for the communication between the server (the
// front-end and its responder (the back-end). So, only a part of DNS
// info can be represented.
type DNSresponse struct {
	Responsecode uint
	Ansection    []RR
	// TODO: allow to have other sections?
}

// TODO: provides a String() method

// This type is used for the communication between the server (the
// front-end and its responder (the back-end). So, only a part of DNS
// info can be represented.
type DNSquery struct {
	Client     net.Addr
	Qname      string
	Qclass     uint16
	Qtype      uint16
	BufferSize uint16
}

// TODO: provides a String() method

// Probably obsolete, will be deleted
type DNSheader struct {
	Qid                                uint16
	Misc                               uint16
	Qdcount, Ancount, Nscount, Arcount uint16
}

// This type represents the DNS packet, with all its fields, as
// described in RFC 1035, section 4.1. So, it is a bit long
type DNSpacket struct {
	Id                                 uint16
	Opcode                             uint
	Rcode                              uint
	Edns                               bool
	EdnsBufferSize                     uint16
	Query, Recursion, Authoritative    bool
	Qdcount, Ancount, Arcount, Nscount uint16 // Question, Answer, Additional and Authority. May be use the implicit length
	// of the following arrays, instead?
	Qsection  []Qentry
	Ansection []RR // Answer section
	Arsection []RR // Additional section
	// TODO: other sections
	Nsid bool // RFC 5001
}

func (packet DNSpacket) String() string {
	return fmt.Sprintf("Query is %t, Opcode is %d, Recursion is %t, Rcode is %d, FQDN is %s, type is %d, class is %d",
		packet.Query, packet.Opcode, packet.Recursion, packet.Rcode, packet.Qsection[0].Qname, packet.Qsection[0].Qtype, packet.Qsection[0].Qclass)
}

// Entries in the Question section. RFC 1035, section 4.1.2
type Qentry struct {
	Qname         string
	Qtype, Qclass uint16
}

// Entries in Answer, Authority and NS sections. RFC 1035, section 4.1.3
type RR struct {
	Name        string
	Type, Class uint16
	TTL         uint32
	// Length is implicit
	Data []byte
}

type SOArecord struct {
	Mname                  string
	Rname                  string
	Serial                 uint32
	Refresh, Retry, Expire uint32
	Minimum                uint32
}

const (
	// Response codes
	NOERROR  = 0
	FORMERR  = 1
	SERVFAIL = 2
	NXDOMAIN = 3
	NOTIMPL  = 4
	REFUSED  = 5

	// Classes
	IN = 1
	CS = 2
	CH = 3
	HS = 4

	// Types
	A     = 1
	NS    = 2
	SOA   = 6
	PTR   = 12
	HINFO = 13
	MX    = 15
	TXT   = 16
	AAAA  = 28
	OPT   = 41
	ALL   = 255

	// Opcodes
	STDQUERY = 0
	IQUERY   = 1
	STATUS   = 2

	// EDNS Option codes
	NSID = 3
)

// Various utility functions

// Converts a string to the wire format {length, data}
func ToTXT(s string) []byte {
	result := make([]byte, 1+len(s))
	result[0] = uint8(len(s))
	for i := 0; i < len(s); i++ {
		result[i+1] = s[i]
	}
	return result
}

// Encodes a FQDN in wire-format (for each label, length+data)
// TODO: see packDomainName in net/dnsmsg.go.
func Encode(name string) []byte {
	var (
		totalresult []byte
	)
	labels := make([]string, 0)
	if name != "." { // The root is a special case. See issue #4
		labels = strings.Split(name, ".")
	}
	totallength := 0
	totalresult = make([]byte, 256) // TODO what a waste
	for _, label := range labels {
		result := make([]byte, 1+len(label))
		result[0] = uint8(len(label))
		for i := 0; i < len(label); i++ {
			result[i+1] = label[i]
		}
		for i := 0; i < 1+len(label); i++ {
			totalresult[totallength+i] = result[i]
		}
		totallength = totallength + int(result[0]) + 1
	}
	totalresult[totallength] = 0 // Domain names end in a null byte for the root
	totallength++
	return totalresult[0:totallength]
}

func EncodeSOA(soa SOArecord) []byte {
	var (
		result []byte
		temp32 []byte
	)
	mname := Encode(soa.Mname)
	length := len(mname)
	rname := Encode(soa.Rname)
	length = length + len(rname)
	length = length + (5 * 4) // Five 32-bits counter at the end
	/* "It's probably cleaner to write to a bytes.Buffer than to
	repeatedly call bytes.Add." Russ Cox, go-nuts ML */
	result = append(result, mname...)
	result = append(result, rname...)
	temp32 = make([]byte, 4)
	binary.BigEndian.PutUint32(temp32, soa.Serial)
	result = append(result, temp32...)
	binary.BigEndian.PutUint32(temp32, soa.Refresh)
	result = append(result, temp32...)
	binary.BigEndian.PutUint32(temp32, soa.Retry)
	result = append(result, temp32...)
	binary.BigEndian.PutUint32(temp32, soa.Expire)
	result = append(result, temp32...)
	binary.BigEndian.PutUint32(temp32, soa.Minimum)
	result = append(result, temp32...)
	return result[0:length]
}
