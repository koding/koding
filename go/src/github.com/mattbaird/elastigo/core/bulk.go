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
	"encoding/json"
	u "github.com/araddon/gou"
	"github.com/mattbaird/elastigo/api"
	"io"
	"log"
	"strconv"
	"sync"
	"time"
	"fmt"
	"errors"
)

var (
	// Max buffer size in bytes before flushing to elasticsearch
	BulkMaxBuffer = 1048576
	// Max number of Docs to hold in buffer before forcing flush
	BulkMaxDocs = 100
	// Max delay before forcing a flush to Elasticearch
	BulkDelaySeconds = 5
	// Keep a running total of errors seen, since it is in the background
	BulkErrorCt uint64
	// maximum wait shutdown seconds
	MAX_SHUTDOWN_SECS = 5

	// There is one Global Bulk Indexor for convenience
	GlobalBulkIndexor *BulkIndexor
)

type ErrorBuffer struct {
	Err error
	Buf *bytes.Buffer
}

// There is one global bulk indexor available for convenience so the IndexBulk() function can be called.
// However, the recommended usage is create your own BulkIndexor to allow for multiple seperate elasticsearch
// servers/host connections.
//    @maxConns is the max number of in flight http requests
//    @done is a channel to cause the indexor to stop
//
//   done := make(chan bool)
//   BulkIndexorGlobalRun(100, done)
func BulkIndexorGlobalRun(maxConns int, done chan bool) {
	if GlobalBulkIndexor == nil {
		GlobalBulkIndexor = NewBulkIndexor(maxConns)
		GlobalBulkIndexor.Run(done)
	}
}

// A bulk indexor creates goroutines, and channels for connecting and sending data
// to elasticsearch in bulk, using buffers.
type BulkIndexor struct {

	// We are creating a variable defining the func responsible for sending
	// to allow a mock sendor for test purposes
	BulkSendor func(*bytes.Buffer) error

	// If we encounter an error in sending, we are going to retry for this long
	// before returning an error
	// if 0 it will not retry
	RetryForSeconds int

	// channel for getting errors
	ErrorChannel chan *ErrorBuffer

	// channel for sending to background indexor
	bulkChannel chan []byte

	// shutdown channel
	shutdownChan chan bool

	// Channel to send a complete byte.Buffer to the http sendor
	sendBuf chan *bytes.Buffer
	// byte buffer for docs that have been converted to bytes, but not yet sent
	buf *bytes.Buffer
	// Buffer for Max number of time before forcing flush
	BufferDelayMax time.Duration
	// Max buffer size in bytes before flushing to elasticsearch
	BulkMaxBuffer int // 1048576
	// Max number of Docs to hold in buffer before forcing flush
	BulkMaxDocs int // 100

	// Number of documents we have send through so far on this session
	docCt int
	// Max number of http connections in flight at one time
	maxConns int
	// If we are indexing enough docs per bufferdelaymax, we won't need to do time
	// based eviction, else we do.
	needsTimeBasedFlush bool
	// Lock for document writes/operations
	mu sync.Mutex
	// Wait Group for the http sends
	sendWg *sync.WaitGroup
}

func NewBulkIndexor(maxConns int) *BulkIndexor {
	b := BulkIndexor{sendBuf: make(chan *bytes.Buffer, maxConns)}
	b.needsTimeBasedFlush = true
	b.buf = new(bytes.Buffer)
	b.maxConns = maxConns
	b.BulkMaxBuffer = BulkMaxBuffer
	b.BulkMaxDocs = BulkMaxDocs
	b.BufferDelayMax = time.Duration(BulkDelaySeconds) * time.Second
	b.bulkChannel = make(chan []byte, 100)
	b.sendWg = new(sync.WaitGroup)
	return &b
}

// A bulk indexor with more control over error handling
//    @maxConns is the max number of in flight http requests
//    @retrySeconds is # of seconds to wait before retrying falied requests
//
//   done := make(chan bool)
//   BulkIndexorGlobalRun(100, done)
func NewBulkIndexorErrors(maxConns, retrySeconds int) *BulkIndexor {
	b := NewBulkIndexor(maxConns)
	b.RetryForSeconds = retrySeconds
	b.ErrorChannel = make(chan *ErrorBuffer, 20)
	return b
}

// Starts this bulk Indexor running, this Run opens a go routine so is
// Non blocking
func (b *BulkIndexor) Run(done chan bool) {

	go func() {
		if b.BulkSendor == nil {
			b.BulkSendor = BulkSend
		}
		b.shutdownChan = done
		b.startHttpSendor()
		b.startDocChannel()
		b.startTimer()
		<-b.shutdownChan
		b.Flush()
	}()
}

// Make a channel that will close when the given WaitGroup is done.
func wgChan(wg *sync.WaitGroup) <-chan interface{} {
	ch := make(chan interface{})
	go func() {
		wg.Wait()
		close(ch)
	}()
	return ch
}

// Flush all current documents to ElasticSearch
func (b *BulkIndexor) Flush() {
	b.mu.Lock()
	if b.docCt > 0 {
		b.send(b.buf)
	}
	b.mu.Unlock()
	for {
		select {
		case <-wgChan(b.sendWg):
			// done
			u.Info("Normal Wait Group Shutdown")
			return
		case <-time.After(time.Second * time.Duration(MAX_SHUTDOWN_SECS)):
			// timeout!
			u.Error("Timeout in Shutdown!")
			return
		}
	}
}

func (b *BulkIndexor) startHttpSendor() {

	// this sends http requests to elasticsearch it uses maxConns to open up that
	// many goroutines, each of which will synchronously call ElasticSearch
	// in theory, the whole set will cause a backup all the way to IndexBulk if
	// we have consumed all maxConns
	for i := 0; i < b.maxConns; i++ {
		go func() {
			for {
				buf := <-b.sendBuf
				b.sendWg.Add(1)
				err := b.BulkSendor(buf)

				// Perhaps a b.FailureStrategy(err)  ??  with different types of strategies
				//  1.  Retry, then panic
				//  2.  Retry then return error and let runner decide
				//  3.  Retry, then log to disk?   retry later?
				if err != nil {
					if b.RetryForSeconds > 0 {
						time.Sleep(time.Second * time.Duration(b.RetryForSeconds))
						err = b.BulkSendor(buf)
						if err == nil {
							// Successfully re-sent with no error
							b.sendWg.Done()
							continue
						}
					}
					if b.ErrorChannel != nil {
						log.Println(err)
						b.ErrorChannel <- &ErrorBuffer{err, buf}
					}
				}
				b.sendWg.Done()
			}
		}()
	}
}

// start a timer for checking back and forcing flush ever BulkDelaySeconds seconds
// even if we haven't hit max messages/size
func (b *BulkIndexor) startTimer() {
	ticker := time.NewTicker(b.BufferDelayMax)
	log.Println("Starting timer with delay = ", b.BufferDelayMax)
	go func() {
		for _ = range ticker.C {
			b.mu.Lock()
			// don't send unless last sendor was the time,
			// otherwise an indication of other thresholds being hit
			// where time isn't needed
			if b.buf.Len() > 0 && b.needsTimeBasedFlush {
				b.needsTimeBasedFlush = true
				b.send(b.buf)
			} else if b.buf.Len() > 0 {
				b.needsTimeBasedFlush = true
			}
			b.mu.Unlock()

		}
	}()
}

func (b *BulkIndexor) startDocChannel() {
	// This goroutine accepts incoming byte arrays from the IndexBulk function and
	// writes to buffer
	go func() {
		for docBytes := range b.bulkChannel {
			b.mu.Lock()
			b.docCt += 1
			b.buf.Write(docBytes)
			if b.buf.Len() >= b.BulkMaxBuffer || b.docCt >= b.BulkMaxDocs {
				b.needsTimeBasedFlush = false
				//log.Printf("Send due to size:  docs=%d  bufsize=%d", b.docCt, b.buf.Len())
				b.send(b.buf)
			}
			b.mu.Unlock()
		}
	}()
}

func (b *BulkIndexor) send(buf *bytes.Buffer) {
	//b2 := *b.buf
	b.sendBuf <- buf
	b.buf = new(bytes.Buffer)
	b.docCt = 0
}

// The index bulk API adds or updates a typed JSON document to a specific index, making it searchable.
// it operates by buffering requests, and ocassionally flushing to elasticsearch
// http://www.elasticsearch.org/guide/reference/api/bulk.html
func (b *BulkIndexor) Index(index string, _type string, id, ttl string, date *time.Time, data interface{}) error {
	//{ "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
	by, err := WriteBulkBytes("index", index, _type, id, ttl, date, data)
	if err != nil {
		u.Error(err)
		return err
	}
	b.bulkChannel <- by
	return nil
}

func (b *BulkIndexor) Update(index string, _type string, id, ttl string, date *time.Time, data interface{}) error {
	//{ "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
	by, err := WriteBulkBytes("update", index, _type, id, ttl, date, data)
	if err != nil {
		u.Error(err)
		return err
	}
	b.bulkChannel <- by
	return nil
}

// This does the actual send of a buffer, which has already been formatted
// into bytes of ES formatted bulk data
func BulkSend(buf *bytes.Buffer) error {
	_, err := api.DoCommand("POST", "/_bulk", buf)
	if err != nil {
		log.Println(err)
		BulkErrorCt += 1
		return err
	}
	return nil
}

// Given a set of arguments for index, type, id, data create a set of bytes that is formatted for bulkd index
// http://www.elasticsearch.org/guide/reference/api/bulk.html
func WriteBulkBytes(op string, index string, _type string, id, ttl string, date *time.Time, data interface{}) ([]byte, error) {
	// only index and update are currently supported
	if op != "index" && op != "update" {
		return nil, errors.New(fmt.Sprintf("Operation '%s' is not yet supported", op))
	}

	// First line
	buf := bytes.Buffer{}
	buf.WriteString(fmt.Sprintf(`{"%s":{"_index":"`, op))
	buf.WriteString(index)
	buf.WriteString(`","_type":"`)
	buf.WriteString(_type)
	if len(id) > 0 {
		buf.WriteString(`","_id":"`)
		buf.WriteString(id)
	}

	if op == "update"  {
		buf.WriteString(`","retry_on_conflict":"3`)
		buf.WriteString(ttl)
	}

	if len(ttl) > 0 {
		buf.WriteString(`","ttl":"`)
		buf.WriteString(ttl)
	}
	if date != nil {
		buf.WriteString(`","_timestamp":"`)
		buf.WriteString(strconv.FormatInt(date.UnixNano()/1e6, 10))
	}
	buf.WriteString(`"}}`)
	buf.WriteByte('\n')

	switch v := data.(type) {
	case *bytes.Buffer:
		io.Copy(&buf, v)
	case []byte:
		buf.Write(v)
	case string:
		buf.WriteString(v)
	default:
		body, jsonErr := json.Marshal(data)
		if jsonErr != nil {
			log.Println("Json data error ", data)
			return nil, jsonErr
		}
		buf.Write(body)
	}
	buf.WriteByte('\n')
	return buf.Bytes(), nil
}


// The index bulk API adds or updates a typed JSON document to a specific index, making it searchable.
// it operates by buffering requests, and ocassionally flushing to elasticsearch
//
// This uses the one Global Bulk Indexor, you can also create your own non-global indexors and use the
// Index functions of that
//
// http://www.elasticsearch.org/guide/reference/api/bulk.html
func IndexBulk(index string, _type string, id string, date *time.Time, data interface{}) error {
	//{ "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
	if GlobalBulkIndexor == nil {
		panic("Must have Global Bulk Indexor to use this Func")
	}
	by, err := WriteBulkBytes("index", index, _type, id, "", date, data)
	if err != nil {
		return err
	}
	GlobalBulkIndexor.bulkChannel <- by
	return nil
}

func UpdateBulk(index string, _type string, id string, date *time.Time, data interface{}) error {
	//{ "update" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
	if GlobalBulkIndexor == nil {
		panic("Must have Global Bulk Indexor to use this Func")
	}
	by, err := WriteBulkBytes("update", index, _type, id, "", date, data)
	if err != nil {
		return err
	}
	GlobalBulkIndexor.bulkChannel <- by
	return nil
}

// The index bulk API adds or updates a typed JSON document to a specific index, making it searchable.
// it operates by buffering requests, and ocassionally flushing to elasticsearch.
//
// This uses the one Global Bulk Indexor, you can also create your own non-global indexors and use the
// IndexTtl functions of that
//
// http://www.elasticsearch.org/guide/reference/api/bulk.html
func IndexBulkTtl(index string, _type string, id, ttl string, date *time.Time, data interface{}) error {
	//{ "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
	if GlobalBulkIndexor == nil {
		panic("Must have Global Bulk Indexor to use this Func")
	}
	by, err := WriteBulkBytes("index", index, _type, id, ttl, date, data)
	if err != nil {
		return err
	}
	GlobalBulkIndexor.bulkChannel <- by
	return nil
}


func UpdateBulkTtl(index string, _type string, id, ttl string, date *time.Time, data interface{}) error {
	//{ "update" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }
	if GlobalBulkIndexor == nil {
		panic("Must have Global Bulk Indexor to use this Func")
	}
	by, err := WriteBulkBytes("update", index, _type, id, ttl, date, data)
	if err != nil {
		return err
	}
	GlobalBulkIndexor.bulkChannel <- by
	return nil
}
