package log

import (
	"compress/zlib"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"runtime"
	"strings"
	"time"
)

type GELF struct {
	Version      string  `json:"version"`
	Host         string  `json:"host"`
	ShortMessage string  `json:"short_message"`
	FullMessage  string  `json:"full_message"`
	Timestamp    float64 `json:"timestamp"`
	Level        int     `json:"level"`
	Facility     string  `json:"facility"`
	File         string  `json:"file"`
	Line         int     `json:"line"`
}

var Facility string
var MaxLevel int = 6
var Hostname string
var Server string = "gl.koding.com:12201"
var conn net.Conn

func init() {
	Hostname, _ = os.Hostname()
}

type chunkWriter struct {
	target io.Writer
	data   []byte
}

func (writer *chunkWriter) Write(p []byte) (int, error) {
	writer.data = append(writer.data, p...)
	return len(p), nil
}

func (writer *chunkWriter) Close() {
	if len(writer.data) <= 512 {
		writer.target.Write(writer.data)
		return
	}

	count := (len(writer.data)-1)/500 + 1
	if count > 128 {
		fmt.Println("Logging error: Too many chunks.")
		return
	}

	chunk := make([]byte, 512)
	chunk[0] = 0x1e
	chunk[1] = 0x0f
	rand.Read(chunk[2:10]) // random message id
	chunk[11] = byte(count)
	for i := 0; i < count; i++ {
		chunk[10] = byte(i)
		l := copy(chunk[12:], writer.data[i*500:])
		writer.target.Write(chunk[:12+l])
	}
}

func Send(gelf *GELF) {
	if conn == nil {
		conn, _ = net.Dial("udp", Server)
	}

	chunkW := chunkWriter{conn, make([]byte, 0)}
	compressor := zlib.NewWriter(&chunkW)
	encoder := json.NewEncoder(compressor)
	encoder.Encode(gelf)
	compressor.Close()
	chunkW.Close()
}

func Log(level int, file string, line int, message ...interface{}) {
	if level > MaxLevel {
		return
	}

	messageStrings := make([]string, len(message))
	for i, part := range message {
		if bytes, ok := part.([]byte); ok {
			messageStrings[i] = string(bytes)
		} else {
			messageStrings[i] = fmt.Sprint(part)
		}
	}
	gelf := GELF{
		Version:      "1.0",
		Host:         Hostname,
		ShortMessage: messageStrings[0],
		Timestamp:    float64(time.Now().UnixNano()) / 1e9,
		Level:        level,
		Facility:     Facility,
		File:         file,
		Line:         line,
	}
	if len(messageStrings) > 1 {
		gelf.FullMessage = strings.Join(messageStrings, "\n")
	}
	Send(&gelf)
}

func Emerg(message ...interface{}) {
	Log(0, "", 0, message...)
}

func Alert(message ...interface{}) {
	Log(1, "", 0, message...)
}

func Crit(message ...interface{}) {
	Log(2, "", 0, message...)
}

func Err(message ...interface{}) {
	Log(3, "", 0, message...)
}

func Warn(message ...interface{}) {
	Log(4, "", 0, message...)
}

func Notice(message ...interface{}) {
	Log(5, "", 0, message...)
}

func Info(message ...interface{}) {
	Log(6, "", 0, message...)
}

func Debug(message ...interface{}) {
	Log(7, "", 0, message...)
}

func RecoverAndLog() {
	err := recover()
	if err != nil {
		message := []interface{}{err}
		for i := 2; ; i++ {
			pc, file, line, ok := runtime.Caller(i)
			if !ok {
				break
			}
			fn := runtime.FuncForPC(pc)
			var name string
			if fn != nil {
				name = fn.Name()
			} else {
				name = "<unknown>"
			}
			message = append(message, fmt.Sprintf("at %s (%s:%d)", name, file, line))
		}
		message = message[0 : len(message)-2]
		_, file, line, _ := runtime.Caller(2)
		Log(3, file, line, message...)
	}
}
