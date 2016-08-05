// Copyright 2015 CoreOS, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package storage

import (
	"errors"
	"log"
	"math"
	"math/rand"
	"sync"
	"time"

	"github.com/coreos/etcd/lease"
	"github.com/coreos/etcd/storage/backend"
	"github.com/coreos/etcd/storage/storagepb"
)

var (
	keyBucketName  = []byte("key")
	metaBucketName = []byte("meta")

	// markedRevBytesLen is the byte length of marked revision.
	// The first `revBytesLen` bytes represents a normal revision. The last
	// one byte is the mark.
	markedRevBytesLen      = revBytesLen + 1
	markBytePosition       = markedRevBytesLen - 1
	markTombstone     byte = 't'

	scheduledCompactKeyName = []byte("scheduledCompactRev")
	finishedCompactKeyName  = []byte("finishedCompactRev")

	ErrTxnIDMismatch = errors.New("storage: txn id mismatch")
	ErrCompacted     = errors.New("storage: required revision has been compacted")
	ErrFutureRev     = errors.New("storage: required revision is a future revision")
	ErrCanceled      = errors.New("storage: watcher is canceled")
)

type store struct {
	mu sync.Mutex // guards the following

	b       backend.Backend
	kvindex index

	le lease.Lessor

	currentRev revision
	// the main revision of the last compaction
	compactMainRev int64

	tx    backend.BatchTx
	txnID int64 // tracks the current txnID to verify txn operations

	wg    sync.WaitGroup
	stopc chan struct{}
}

// NewStore returns a new store. It is useful to create a store inside
// storage pkg. It should only be used for testing externally.
func NewStore(b backend.Backend, le lease.Lessor) *store {
	s := &store{
		b:       b,
		kvindex: newTreeIndex(),

		le: le,

		currentRev:     revision{main: 1},
		compactMainRev: -1,
		stopc:          make(chan struct{}),
	}

	if s.le != nil {
		s.le.SetRangeDeleter(s)
	}

	tx := s.b.BatchTx()
	tx.Lock()
	tx.UnsafeCreateBucket(keyBucketName)
	tx.UnsafeCreateBucket(metaBucketName)
	tx.Unlock()
	s.b.ForceCommit()

	if err := s.restore(); err != nil {
		// TODO: return the error instead of panic here?
		panic("failed to recover store from backend")
	}

	return s
}

func (s *store) Rev() int64 {
	s.mu.Lock()
	defer s.mu.Unlock()

	return s.currentRev.main
}

func (s *store) FirstRev() int64 {
	s.mu.Lock()
	defer s.mu.Unlock()

	return s.compactMainRev
}

func (s *store) Put(key, value []byte, lease lease.LeaseID) int64 {
	id := s.TxnBegin()
	s.put(key, value, lease)
	s.txnEnd(id)

	putCounter.Inc()

	return int64(s.currentRev.main)
}

func (s *store) Range(key, end []byte, limit, rangeRev int64) (kvs []storagepb.KeyValue, rev int64, err error) {
	id := s.TxnBegin()
	kvs, rev, err = s.rangeKeys(key, end, limit, rangeRev)
	s.txnEnd(id)

	rangeCounter.Inc()

	return kvs, rev, err
}

func (s *store) DeleteRange(key, end []byte) (n, rev int64) {
	id := s.TxnBegin()
	n = s.deleteRange(key, end)
	s.txnEnd(id)

	deleteCounter.Inc()

	return n, int64(s.currentRev.main)
}

func (s *store) TxnBegin() int64 {
	s.mu.Lock()
	s.currentRev.sub = 0
	s.tx = s.b.BatchTx()
	s.tx.Lock()

	s.txnID = rand.Int63()
	return s.txnID
}

func (s *store) TxnEnd(txnID int64) error {
	err := s.txnEnd(txnID)
	if err != nil {
		return err
	}

	txnCounter.Inc()
	return nil
}

// txnEnd is used for unlocking an internal txn. It does
// not increase the txnCounter.
func (s *store) txnEnd(txnID int64) error {
	if txnID != s.txnID {
		return ErrTxnIDMismatch
	}

	s.tx.Unlock()
	if s.currentRev.sub != 0 {
		s.currentRev.main += 1
	}
	s.currentRev.sub = 0

	dbTotalSize.Set(float64(s.b.Size()))
	s.mu.Unlock()
	return nil
}

func (s *store) TxnRange(txnID int64, key, end []byte, limit, rangeRev int64) (kvs []storagepb.KeyValue, rev int64, err error) {
	if txnID != s.txnID {
		return nil, 0, ErrTxnIDMismatch
	}
	return s.rangeKeys(key, end, limit, rangeRev)
}

func (s *store) TxnPut(txnID int64, key, value []byte, lease lease.LeaseID) (rev int64, err error) {
	if txnID != s.txnID {
		return 0, ErrTxnIDMismatch
	}

	s.put(key, value, lease)
	return int64(s.currentRev.main + 1), nil
}

func (s *store) TxnDeleteRange(txnID int64, key, end []byte) (n, rev int64, err error) {
	if txnID != s.txnID {
		return 0, 0, ErrTxnIDMismatch
	}

	n = s.deleteRange(key, end)
	if n != 0 || s.currentRev.sub != 0 {
		rev = int64(s.currentRev.main + 1)
	} else {
		rev = int64(s.currentRev.main)
	}
	return n, rev, nil
}

func (s *store) Compact(rev int64) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if rev <= s.compactMainRev {
		return ErrCompacted
	}
	if rev > s.currentRev.main {
		return ErrFutureRev
	}

	start := time.Now()

	s.compactMainRev = rev

	rbytes := newRevBytes()
	revToBytes(revision{main: rev}, rbytes)

	tx := s.b.BatchTx()
	tx.Lock()
	tx.UnsafePut(metaBucketName, scheduledCompactKeyName, rbytes)
	tx.Unlock()
	// ensure that desired compaction is persisted
	s.b.ForceCommit()

	keep := s.kvindex.Compact(rev)

	s.wg.Add(1)
	go s.scheduleCompaction(rev, keep)

	indexCompactionPauseDurations.Observe(float64(time.Now().Sub(start) / time.Millisecond))
	return nil
}

func (s *store) Hash() (uint32, error) {
	s.b.ForceCommit()
	return s.b.Hash()
}

func (s *store) Commit() { s.b.ForceCommit() }

func (s *store) Restore(b backend.Backend) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	close(s.stopc)
	// TODO: restore without waiting for compaction routine to finish.
	// We need a way to notify that the store is finished using the old
	// backend though.
	s.wg.Wait()

	s.b = b
	s.kvindex = newTreeIndex()
	s.currentRev = revision{main: 1}
	s.compactMainRev = -1
	s.tx = b.BatchTx()
	s.txnID = -1
	s.stopc = make(chan struct{})

	return s.restore()
}

func (s *store) restore() error {
	min, max := newRevBytes(), newRevBytes()
	revToBytes(revision{main: 1}, min)
	revToBytes(revision{main: math.MaxInt64, sub: math.MaxInt64}, max)

	// restore index
	tx := s.b.BatchTx()
	tx.Lock()
	_, finishedCompactBytes := tx.UnsafeRange(metaBucketName, finishedCompactKeyName, nil, 0)
	if len(finishedCompactBytes) != 0 {
		s.compactMainRev = bytesToRev(finishedCompactBytes[0]).main
		log.Printf("storage: restore compact to %d", s.compactMainRev)
	}

	// TODO: limit N to reduce max memory usage
	keys, vals := tx.UnsafeRange(keyBucketName, min, max, 0)
	for i, key := range keys {
		var kv storagepb.KeyValue
		if err := kv.Unmarshal(vals[i]); err != nil {
			log.Fatalf("storage: cannot unmarshal event: %v", err)
		}

		rev := bytesToRev(key[:revBytesLen])

		// restore index
		switch {
		case isTombstone(key):
			// TODO: De-attach keys from lease if necessary
			s.kvindex.Tombstone(kv.Key, rev)
		default:
			s.kvindex.Restore(kv.Key, revision{kv.CreateRevision, 0}, rev, kv.Version)
			if lease.LeaseID(kv.Lease) != lease.NoLease {
				if s.le == nil {
					panic("no lessor to attach lease")
				}
				err := s.le.Attach(lease.LeaseID(kv.Lease), []lease.LeaseItem{{Key: string(kv.Key)}})
				// We are walking through the kv history here. It is possible that we attached a key to
				// the lease and the lease was revoked later.
				// Thus attaching an old version of key to a none existing lease is possible here, and
				// we should just ignore the error.
				if err != nil && err != lease.ErrLeaseNotFound {
					panic("unexpected Attach error")
				}
			}
		}

		// update revision
		s.currentRev = rev
	}

	_, scheduledCompactBytes := tx.UnsafeRange(metaBucketName, scheduledCompactKeyName, nil, 0)
	if len(scheduledCompactBytes) != 0 {
		scheduledCompact := bytesToRev(scheduledCompactBytes[0]).main
		if scheduledCompact > s.compactMainRev {
			log.Printf("storage: resume scheduled compaction at %d", scheduledCompact)
			go s.Compact(scheduledCompact)
		}
	}

	tx.Unlock()

	return nil
}

func (s *store) Close() error {
	close(s.stopc)
	s.wg.Wait()
	return nil
}

func (a *store) Equal(b *store) bool {
	if a.currentRev != b.currentRev {
		return false
	}
	if a.compactMainRev != b.compactMainRev {
		return false
	}
	return a.kvindex.Equal(b.kvindex)
}

// range is a keyword in Go, add Keys suffix.
func (s *store) rangeKeys(key, end []byte, limit, rangeRev int64) (kvs []storagepb.KeyValue, rev int64, err error) {
	curRev := int64(s.currentRev.main)
	if s.currentRev.sub > 0 {
		curRev += 1
	}

	if rangeRev > curRev {
		return nil, s.currentRev.main, ErrFutureRev
	}
	if rangeRev <= 0 {
		rev = curRev
	} else {
		rev = rangeRev
	}
	if rev <= s.compactMainRev {
		return nil, 0, ErrCompacted
	}

	_, revpairs := s.kvindex.Range(key, end, int64(rev))
	if len(revpairs) == 0 {
		return nil, rev, nil
	}

	for _, revpair := range revpairs {
		start, end := revBytesRange(revpair)

		_, vs := s.tx.UnsafeRange(keyBucketName, start, end, 0)
		if len(vs) != 1 {
			log.Fatalf("storage: range cannot find rev (%d,%d)", revpair.main, revpair.sub)
		}

		var kv storagepb.KeyValue
		if err := kv.Unmarshal(vs[0]); err != nil {
			log.Fatalf("storage: cannot unmarshal event: %v", err)
		}
		kvs = append(kvs, kv)
		if limit > 0 && len(kvs) >= int(limit) {
			break
		}
	}
	return kvs, rev, nil
}

func (s *store) put(key, value []byte, leaseID lease.LeaseID) {
	rev := s.currentRev.main + 1
	c := rev

	// if the key exists before, use its previous created
	_, created, ver, err := s.kvindex.Get(key, rev)
	if err == nil {
		c = created.main
	}

	ibytes := newRevBytes()
	revToBytes(revision{main: rev, sub: s.currentRev.sub}, ibytes)

	ver = ver + 1
	kv := storagepb.KeyValue{
		Key:            key,
		Value:          value,
		CreateRevision: c,
		ModRevision:    rev,
		Version:        ver,
		Lease:          int64(leaseID),
	}

	d, err := kv.Marshal()
	if err != nil {
		log.Fatalf("storage: cannot marshal event: %v", err)
	}

	s.tx.UnsafePut(keyBucketName, ibytes, d)
	s.kvindex.Put(key, revision{main: rev, sub: s.currentRev.sub})
	s.currentRev.sub += 1

	if leaseID != lease.NoLease {
		if s.le == nil {
			panic("no lessor to attach lease")
		}

		// TODO: validate the existence of lease before call Attach.
		// We need to ensure put always successful since we do not want
		// to handle abortion for txn request. We need to ensure all requests
		// inside the txn can execute without error before executing them.
		err = s.le.Attach(leaseID, []lease.LeaseItem{{Key: string(key)}})
		if err != nil {
			panic("unexpected error from lease Attach")
		}
	}
}

func (s *store) deleteRange(key, end []byte) int64 {
	rrev := s.currentRev.main
	if s.currentRev.sub > 0 {
		rrev += 1
	}
	keys, _ := s.kvindex.Range(key, end, rrev)

	if len(keys) == 0 {
		return 0
	}

	for _, key := range keys {
		s.delete(key)
	}
	return int64(len(keys))
}

func (s *store) delete(key []byte) {
	mainrev := s.currentRev.main + 1

	ibytes := newRevBytes()
	revToBytes(revision{main: mainrev, sub: s.currentRev.sub}, ibytes)
	ibytes = appendMarkTombstone(ibytes)

	kv := storagepb.KeyValue{
		Key: key,
	}

	d, err := kv.Marshal()
	if err != nil {
		log.Fatalf("storage: cannot marshal event: %v", err)
	}

	s.tx.UnsafePut(keyBucketName, ibytes, d)
	err = s.kvindex.Tombstone(key, revision{main: mainrev, sub: s.currentRev.sub})
	if err != nil {
		log.Fatalf("storage: cannot tombstone an existing key (%s): %v", string(key), err)
	}
	s.currentRev.sub += 1

	// TODO: De-attach keys from lease if necessary
}

// appendMarkTombstone appends tombstone mark to normal revision bytes.
func appendMarkTombstone(b []byte) []byte {
	if len(b) != revBytesLen {
		log.Panicf("cannot append mark to non normal revision bytes")
	}
	return append(b, markTombstone)
}

// isTombstone checks whether the revision bytes is a tombstone.
func isTombstone(b []byte) bool {
	return len(b) == markedRevBytesLen && b[markBytePosition] == markTombstone
}

// revBytesRange returns the range of revision bytes at
// the given revision.
func revBytesRange(rev revision) (start, end []byte) {
	start = newRevBytes()
	revToBytes(rev, start)

	end = newRevBytes()
	endRev := revision{main: rev.main, sub: rev.sub + 1}
	revToBytes(endRev, end)

	return start, end
}
