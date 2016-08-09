// package mms implements encoding of binary MMS payload.
//
// http://technical.openmobilealliance.org/tech/affiliates/wap/wapindex.html
// http://technical.openmobilealliance.org/Technical/release_program/mms_v1_3.aspx
package mms

import (
	"fmt"
	"io"
	"time"
)

// Header IDs: WAP-209, section 7.3
const (
	HdrBCC = iota + 1
	HdrCC
	HdrContentLocation
	HdrContentType
	HdrDate // 5
	HdrDeliveryReport
	HdrDeliveryTime
	HdrExpiry
	HdrFrom
	HdrMessageClass // 10
	HdrMessageID
	HdrMessageType
	HdrMMSVersion
	HdrMessageSize
	HdrPriority // 15
	HdrReadReply
	HdrReportAllowed
	HdrResponseStatus
	HdrResponseText
	HdrSenderVisibility // 20
	HdrStatus
	HdrSubject
	HdrTo
	HdrTransactionID
)

var headerNames = [...]string{
	HdrBCC:              "Bcc",
	HdrCC:               "Cc",
	HdrContentLocation:  "Content-Location",
	HdrContentType:      "Content-Type",
	HdrDate:             "Date",
	HdrDeliveryReport:   "Delivery-Report",
	HdrDeliveryTime:     "Delivery-Time",
	HdrExpiry:           "Expiry",
	HdrFrom:             "From",
	HdrMessageClass:     "Message-Class",
	HdrMessageID:        "Message-ID",
	HdrMessageType:      "Message-Type",
	HdrMMSVersion:       "MMS-Version",
	HdrMessageSize:      "Message-Size",
	HdrPriority:         "Priority",
	HdrReadReply:        "Read-Reply",
	HdrReportAllowed:    "Report-Allowed",
	HdrResponseStatus:   "Response-Status",
	HdrResponseText:     "Response-Text",
	HdrSenderVisibility: "Sender-Visibility",
	HdrStatus:           "Status",
	HdrSubject:          "Subject",
	HdrTo:               "To",
	HdrTransactionID:    "Transaction-Id",
}

const (
	hdrEncodedString = iota
	hdrContentType
	hdrBool
	hdrEnum
	hdrShortInt
	hdrLongInt
	hdrUnixTime
	hdrTime // Date or relative delta
	hdrAddress
)

var headerTypes = [...]int{
	HdrBCC:              hdrEncodedString,
	HdrCC:               hdrEncodedString,
	HdrContentLocation:  hdrEncodedString,
	HdrContentType:      hdrContentType,
	HdrDate:             hdrUnixTime,
	HdrDeliveryReport:   hdrBool,
	HdrDeliveryTime:     hdrTime,
	HdrExpiry:           hdrTime,
	HdrFrom:             hdrAddress,
	HdrMessageClass:     hdrEnum,
	HdrMessageID:        hdrEncodedString,
	HdrMessageType:      hdrEnum,
	HdrMMSVersion:       hdrShortInt,
	HdrMessageSize:      hdrLongInt,
	HdrPriority:         hdrEnum,
	HdrReadReply:        hdrBool,
	HdrReportAllowed:    hdrBool,
	HdrResponseStatus:   hdrEnum,
	HdrResponseText:     hdrEncodedString,
	HdrSenderVisibility: hdrBool,
	HdrStatus:           hdrEnum,
	HdrSubject:          hdrEncodedString,
	HdrTo:               hdrEncodedString,
	HdrTransactionID:    hdrEncodedString,
}

type ByteReader interface {
	io.Reader
	io.ByteReader
	ReadString(byte) (string, error)
}

type MMS struct {
	Header map[string]string
}

func ReadMMS(r ByteReader) (mms MMS, err error) {
	// Read headers.
	for {
		b, err := r.ReadByte()
		if b <= 0x80 || b >= byte(0x80+len(headerTypes)) {
			return mms, fmt.Errorf("invalid header ID: %x", b)
		}
		key := headerNames[b-0x80]
		var value string
		// See WAP-230-WSP, section 8.4.2.1
		switch typ := headerTypes[b-0x80]; typ {
		case hdrBool, hdrEnum:
			b, err = r.ReadByte()
			value = fmt.Sprint(b - 0x80)
		case hdrEncodedString:
			value, err = r.ReadString(0)
			value = value[:len(value)-1]
		case hdrContentType:
		case hdrLongInt, hdrUnixTime:
			// big-endian, variable length.
			b, err = r.ReadByte()
			if b > 8 {
				return mms, fmt.Errorf("integer too large")
			}
			var x [8]byte
			_, err = io.ReadFull(r, x[:b])
			n := uint64(0)
			for _, c := range x[:b] {
				n = (n << 8) | uint64(c)
			}
			if typ == hdrUnixTime {
				value = time.Unix(int64(n), 0).Format(time.RFC1123Z)
			} else {
				value = fmt.Sprint(n)
			}
		case hdrTime:
			b, err = r.ReadByte() // length.
			var buf [8]byte
			_, err = io.ReadFull(r, buf[:b])
			// buf[0] is type, buf[1] is int-length.
			var n uint64
			for _, c := range buf[2 : 2+buf[1]] {
				n = (n << 8) | uint64(c)
			}
			switch buf[0] { // type
			case 0x80:
				value = time.Unix(int64(n), 0).Format(time.RFC1123Z)
			case 0x81:
				value = (time.Duration(n) * time.Second).String()
			default:
				return mms, fmt.Errorf("invalid type for address: 0x%x", b)
			}
		case hdrAddress:
			b, err = r.ReadByte() // length
			s := make([]byte, b)
			_, err = io.ReadFull(r, s)
			switch s[0] { // type
			case 0x80:
				value = string(s[1:])
			case 0x81:
				// FIXME.
				value = string(s[1:])
			default:
				return mms, fmt.Errorf("invalid type for address: 0x%x", s[0])
			}
		case hdrShortInt:
			// single byte.
			b, err = r.ReadByte()
			value = fmt.Sprint(b - 0x80)
		}
		if mms.Header == nil {
			mms.Header = make(map[string]string)
		}
		print(key, ": ", value, "\n")
		mms.Header[key] = value
		if err != nil {
			return mms, err
		}
	}
}
