package log

import (
	"compress/zlib"
	"crypto/rand"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net"
	"os"
	"runtime"
	"strings"
	"time"
)

type GelfMessage struct {
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

func (gelf *GelfMessage) String() string {
	str := fmt.Sprintf("%-6v %v", LEVEL_NAMES[gelf.Level], gelf.ShortMessage)
	if gelf.FullMessage != "" {
		str += "\n" + gelf.FullMessage
	}
	return str
}

var Facility string
var MaxLevel int = 6
var Verbose bool = false
var Hostname string
var Server string = "gl.koding.com:12201"
var conn net.Conn

func init() {
	flag.IntVar(&MaxLevel, "l", 6, "Log level")
	flag.BoolVar(&Verbose, "v", false, "Logging to console instead of Graylog")
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

func NewGelfMessage(level int, file string, line int, message ...interface{}) *GelfMessage {
	messageStrings := make([]string, len(message))
	for i, part := range message {
		if bytes, ok := part.([]byte); ok {
			messageStrings[i] = string(bytes)
		} else {
			messageStrings[i] = fmt.Sprint(part)
		}
	}
	gelf := GelfMessage{
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
	return &gelf
}

func Send(gelf interface{}) {
	if Verbose {
		fmt.Println(gelf)
		return
	}

	data, err := json.Marshal(gelf)
	if err != nil {
		fmt.Println("logger error: json.Marshal failed")
		return
	}

	if conn == nil {
		conn, _ = net.Dial("udp", Server)
	}
	chunkW := chunkWriter{conn, make([]byte, 0)}
	compressor := zlib.NewWriter(&chunkW)
	compressor.Write(data)
	compressor.Close()
	chunkW.Close()
}

func Log(level int, file string, line int, message ...interface{}) {
	if level > MaxLevel {
		return
	}
	Send(NewGelfMessage(level, file, line, message...))
}

const (
	EMERG  = 0
	ALERT  = 1
	CRIT   = 2
	ERR    = 3
	WARN   = 4
	NOTICE = 5
	INFO   = 6
	DEBUG  = 7
)

var LEVEL_NAMES = []string{"EMERG", "ALERT", "CRIT", "ERR", "WARN", "NOTICE", "INFO", "DEBUG"}

func Emerg(message ...interface{}) {
	Log(EMERG, "", 0, message...)
}

func Alert(message ...interface{}) {
	Log(ALERT, "", 0, message...)
}

func Crit(message ...interface{}) {
	Log(CRIT, "", 0, message...)
}

func Err(message ...interface{}) {
	Log(ERR, "", 0, message...)
}

func Warn(message ...interface{}) {
	Log(WARN, "", 0, message...)
}

func Notice(message ...interface{}) {
	Log(NOTICE, "", 0, message...)
}

func Info(message ...interface{}) {
	Log(INFO, "", 0, message...)
}

func Debug(message ...interface{}) {
	Log(DEBUG, "", 0, message...)
}

func LogError(err interface{}) {
	message := []interface{}{err}
	for i := 3; ; i++ {
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
	_, file, line, _ := runtime.Caller(2)
	Log(ERR, file, line, message...)
}

func RecoverAndLog() {
	err := recover()
	if err != nil {
		LogError(err)
	}
}
