// Copyright 2013 Matthew Baird
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package core

import (
	"bytes"
	"crypto/rand"
	"encoding/json"
	"flag"
	u "github.com/araddon/gou"
	"github.com/mattbaird/elastigo/api"
	"log"
	"strconv"
	"testing"
	"time"
)

//  go test -bench=".*"
//  go test -bench="Bulk"

var (
	buffers        = make([]*bytes.Buffer, 0)
	totalBytesSent int
	messageSets    int
)

func init() {
	flag.Parse()
	if testing.Verbose() {
		u.SetupLogging("debug")
	}
}
func TestBulkIndexorBasic(t *testing.T) {
	InitTests(true)
	indexor := NewBulkIndexor(3)
	indexor.BulkSendor = func(buf *bytes.Buffer) error {
		messageSets += 1
		totalBytesSent += buf.Len()
		buffers = append(buffers, buf)
		u.Debug(string(buf.Bytes()))
		return BulkSend(buf)
	}
	done := make(chan bool)
	indexor.Run(done)

	date := time.Unix(1257894000, 0)
	data := map[string]interface{}{"name": "smurfs", "age": 22, "date": time.Unix(1257894000, 0)}
	err := indexor.Index("users", "user", "1", "", &date, data)

	WaitFor(func() bool {
		return len(buffers) > 0
	}, 5)
	// part of request is url, so lets factor that in
	//totalBytesSent = totalBytesSent - len(*eshost)
	u.Assert(len(buffers) == 1, t, "Should have sent one operation but was %d", len(buffers))
	u.Assert(BulkErrorCt == 0 && err == nil, t, "Should not have any errors  %v", err)
	u.Assert(totalBytesSent == 145, t, "Should have sent 135 bytes but was %v", totalBytesSent)

	err = indexor.Index("users", "user", "2", "", nil, data)
	<-time.After(time.Millisecond * 10) // we need to wait for doc to hit send channel
	// this will test to ensure that Flush actually catches a doc
	indexor.Flush()
	totalBytesSent = totalBytesSent - len(*eshost)
	u.Assert(err == nil, t, "Should have nil error  =%v", err)
	u.Assert(len(buffers) == 2, t, "Should have another buffer ct=%d", len(buffers))

	u.Assert(BulkErrorCt == 0, t, "Should not have any errors %d", BulkErrorCt)
	u.Assert(u.CloseInt(totalBytesSent, 257), t, "Should have sent 257 bytes but was %v", totalBytesSent)

}

func TestBulkUpdate(t *testing.T) {
	InitTests(true)
	api.Port = "9200"
	indexor := NewBulkIndexor(3)
	indexor.BulkSendor = func(buf *bytes.Buffer) error {
		messageSets += 1
		totalBytesSent += buf.Len()
		buffers = append(buffers, buf)
		u.Debug(string(buf.Bytes()))
		return BulkSend(buf)
	}
	done := make(chan bool)
	indexor.Run(done)

	date := time.Unix(1257894000, 0)
	user := map[string]interface{}{
		"name": "smurfs", "age": 22, "date": time.Unix(1257894000, 0), "count": 1,
	}

	// Lets make sure the data is in the index ...
	_, err := Index(true, "users", "user", "5", user)

	// script and params
	data := map[string]interface{}{
		"script": "ctx._source.count += 2",
	}
	err = indexor.Update("users", "user", "5", "", &date, data)
	// So here's the deal. Flushing does seem to work, you just have to give the
	// channel a moment to recieve the message ...
//	<- time.After(time.Millisecond * 20)
//	indexor.Flush()
	done <- true

	WaitFor(func() bool {
			return len(buffers) > 0
		}, 5)

	u.Assert(BulkErrorCt == 0 && err == nil, t, "Should not have any errors  %v", err)

	response, err := Get(true, "users", "user", "5")
	u.Assert(err == nil, t, "Should not have any errors  %v", err)
	newCount := response.Source.(map[string]interface {})["count"]
	u.Assert( newCount.(float64) == 3, t, "Should have update count: %#v ... %#v", response.Source.(map[string]interface {})["count"], response)
}

func TestBulkSmallBatch(t *testing.T) {
	InitTests(true)

	done := make(chan bool)

	date := time.Unix(1257894000, 0)
	data := map[string]interface{}{"name": "smurfs", "age": 22, "date": time.Unix(1257894000, 0)}

	// Now tests small batches
	indexorsm := NewBulkIndexor(1)
	indexorsm.BufferDelayMax = 100 * time.Millisecond
	indexorsm.BulkMaxDocs = 2
	messageSets = 0
	indexorsm.BulkSendor = func(buf *bytes.Buffer) error {
		messageSets += 1
		return BulkSend(buf)
	}
	indexorsm.Run(done)
	<-time.After(time.Millisecond * 20)

	indexorsm.Index("users", "user", "2", "", &date, data)
	indexorsm.Index("users", "user", "3", "", &date, data)
	indexorsm.Index("users", "user", "4", "", &date, data)
	<-time.After(time.Millisecond * 200)
//	indexorsm.Flush()
	done <- true
	Assert(messageSets == 2, t, "Should have sent 2 message sets %d", messageSets)

}

func TestBulkErrors(t *testing.T) {
	// lets set a bad port, and hope we get a connection refused error?
	api.Port = "27845"
	defer func() {
		api.Port = "9200"
	}()
	BulkDelaySeconds = 1
	indexor := NewBulkIndexorErrors(10, 1)
	done := make(chan bool)
	indexor.Run(done)

	errorCt := 0
	go func() {
		for i := 0; i < 20; i++ {
			date := time.Unix(1257894000, 0)
			data := map[string]interface{}{"name": "smurfs", "age": 22, "date": time.Unix(1257894000, 0)}
			indexor.Index("users", "user", strconv.Itoa(i), "", &date, data)
		}
	}()
	for errBuf := range indexor.ErrorChannel {
		errorCt++
		u.Debug(errBuf.Err)
		break
	}
	u.Assert(errorCt > 0, t, "ErrorCt should be > 0 %d", errorCt)

}

/*
BenchmarkBulkSend	18:33:00 bulk_test.go:131: Sent 1 messages in 0 sets totaling 0 bytes
18:33:00 bulk_test.go:131: Sent 100 messages in 1 sets totaling 145889 bytes
18:33:01 bulk_test.go:131: Sent 10000 messages in 100 sets totaling 14608888 bytes
18:33:05 bulk_test.go:131: Sent 20000 messages in 99 sets totaling 14462790 bytes
   20000	    234526 ns/op

*/
func BenchmarkBulkSend(b *testing.B) {
	InitTests(true)
	b.StartTimer()
	totalBytes := 0
	sets := 0
	GlobalBulkIndexor.BulkSendor = func(buf *bytes.Buffer) error {
		totalBytes += buf.Len()
		sets += 1
		//log.Println("got bulk")
		return BulkSend(buf)
	}
	for i := 0; i < b.N; i++ {
		about := make([]byte, 1000)
		rand.Read(about)
		data := map[string]interface{}{"name": "smurfs", "age": 22, "date": time.Unix(1257894000, 0), "about": about}
		IndexBulk("users", "user", strconv.Itoa(i), nil, data)
	}
	log.Printf("Sent %d messages in %d sets totaling %d bytes \n", b.N, sets, totalBytes)
	if BulkErrorCt != 0 {
		b.Fail()
	}
}

/*
TODO:  this should be faster than above

BenchmarkBulkSendBytes	18:33:05 bulk_test.go:169: Sent 1 messages in 0 sets totaling 0 bytes
18:33:05 bulk_test.go:169: Sent 100 messages in 2 sets totaling 292299 bytes
18:33:09 bulk_test.go:169: Sent 10000 messages in 99 sets totaling 14473800 bytes
   10000	    373529 ns/op

*/
func BenchmarkBulkSendBytes(b *testing.B) {
	InitTests(true)
	about := make([]byte, 1000)
	rand.Read(about)
	data := map[string]interface{}{"name": "smurfs", "age": 22, "date": time.Unix(1257894000, 0), "about": about}
	body, _ := json.Marshal(data)
	b.StartTimer()
	totalBytes := 0
	sets := 0
	GlobalBulkIndexor.BulkSendor = func(buf *bytes.Buffer) error {
		totalBytes += buf.Len()
		sets += 1
		return BulkSend(buf)
	}
	for i := 0; i < b.N; i++ {
		IndexBulk("users", "user", strconv.Itoa(i), nil, body)
	}
	log.Printf("Sent %d messages in %d sets totaling %d bytes \n", b.N, sets, totalBytes)
	if BulkErrorCt != 0 {
		b.Fail()
	}
}
