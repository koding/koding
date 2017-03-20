package sockjs

import (
	"bytes"
	"strconv"
)

func closeFrame(status uint32, reason string) string {
	return "c[" + strconv.FormatUint(uint64(status), 10) + "," + quote(reason) + "]"
}

func frame(messages []string) string {
	switch len(messages) {
	case 0:
		return ""
	case 1:
		return messageFrame(messages[0])
	default:
		return arrayFrame(messages)
	}
}

func messageFrame(message string) string {
	return "m" + quote(message)
}

func arrayFrame(messages []string) string {
	var buf bytes.Buffer

	buf.WriteString("a[")
	buf.WriteString(quote(messages[0]))

	for _, message := range messages[1:] {
		buf.WriteByte(',')
		buf.WriteString(quote(message))
	}

	buf.WriteByte(']')

	return buf.String()
}
