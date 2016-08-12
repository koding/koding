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

package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"net/http"
	"net/url"

	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	"github.com/coreos/etcd/etcdserver/stats"
	"github.com/coreos/etcd/pkg/types"
	"github.com/coreos/etcd/raft"
	"github.com/coreos/etcd/raft/raftpb"
	"github.com/coreos/etcd/rafthttp"
	"github.com/coreos/etcd/wal"
	"github.com/coreos/etcd/wal/walpb"
)

// A key-value stream backed by raft
type raftNode struct {
	proposeC <-chan string // proposed messages (k,v)
	commitC  chan *string  // entries committed to log (k,v)
	errorC   chan error    // errors from raft session

	id     int      // client ID for raft session
	peers  []string // raft peer URLs
	waldir string   // path to WAL directory

	// raft backing for the commit/error channel
	node        raft.Node
	raftStorage *raft.MemoryStorage
	wal         *wal.WAL
	transport   *rafthttp.Transport
	stopc       chan struct{} // signals proposal channel closed
	httpstopc   chan struct{} // signals http server to shutdown
	httpdonec   chan struct{} // signals http server shutdown complete
}

// newRaftNode initiates a raft instance and returns a committed log entry
// channel and error channel. Proposals for log updates are sent over the
// provided the proposal channel. All log entries are replayed over the
// commit channel, followed by a nil message (to indicate the channel is
// current), then new log entries. To shutdown, close proposeC and read errorC.
func newRaftNode(id int, peers []string, proposeC <-chan string) (<-chan *string, <-chan error) {
	rc := &raftNode{
		proposeC:    proposeC,
		commitC:     make(chan *string),
		errorC:      make(chan error),
		id:          id,
		peers:       peers,
		waldir:      fmt.Sprintf("raftexample-%d", id),
		raftStorage: raft.NewMemoryStorage(),
		stopc:       make(chan struct{}),
		httpstopc:   make(chan struct{}),
		httpdonec:   make(chan struct{}),
		// rest of structure populated after WAL replay
	}
	go rc.startRaft()
	return rc.commitC, rc.errorC
}

// publishEntries writes committed log entries to commit channel and returns
// whether all entries could be published.
func (rc *raftNode) publishEntries(ents []raftpb.Entry) bool {
	for i := range ents {
		if ents[i].Type != raftpb.EntryNormal || len(ents[i].Data) == 0 {
			// ignore conf changes and empty messages
			continue
		}
		s := string(ents[i].Data)
		select {
		case rc.commitC <- &s:
		case <-rc.stopc:
			return false
		}
	}
	return true
}

// openWAL returns a WAL ready for reading.
func (rc *raftNode) openWAL() *wal.WAL {
	if wal.Exist(rc.waldir) == false {
		if err := os.Mkdir(rc.waldir, 0750); err != nil {
			log.Fatalf("raftexample: cannot create dir for wal (%v)", err)
		}

		w, err := wal.Create(rc.waldir, nil)
		if err != nil {
			log.Fatalf("raftexample: create wal error (%v)", err)
		}
		w.Close()
	}

	w, err := wal.Open(rc.waldir, walpb.Snapshot{})
	if err != nil {
		log.Fatalf("raftexample: error loading wal (%v)", err)
	}

	return w
}

// replayWAL replays WAL entries into the raft instance and the commit
// channel and returns an appendable WAL.
func (rc *raftNode) replayWAL() *wal.WAL {
	w := rc.openWAL()
	_, _, ents, err := w.ReadAll()
	if err != nil {
		log.Fatalf("raftexample: failed to read WAL (%v)", err)
	}
	// append to storage so raft starts at the right place in log
	rc.raftStorage.Append(ents)
	rc.publishEntries(ents)
	// send nil value so client knows commit channel is current
	rc.commitC <- nil
	return w
}

func (rc *raftNode) writeError(err error) {
	rc.stopHTTP()
	close(rc.commitC)
	rc.errorC <- err
	close(rc.errorC)
	rc.node.Stop()
}

func (rc *raftNode) startRaft() {
	oldwal := wal.Exist(rc.waldir)
	rc.wal = rc.replayWAL()

	rpeers := make([]raft.Peer, len(rc.peers))
	for i := range rpeers {
		rpeers[i] = raft.Peer{ID: uint64(i + 1)}
	}
	c := &raft.Config{
		ID:              uint64(rc.id),
		ElectionTick:    10,
		HeartbeatTick:   1,
		Storage:         rc.raftStorage,
		MaxSizePerMsg:   1024 * 1024,
		MaxInflightMsgs: 256,
	}

	if oldwal {
		rc.node = raft.RestartNode(c)
	} else {
		rc.node = raft.StartNode(c, rpeers)
	}

	ss := &stats.ServerStats{}
	ss.Initialize()

	rc.transport = &rafthttp.Transport{
		ID:          types.ID(rc.id),
		ClusterID:   0x1000,
		Raft:        rc,
		ServerStats: ss,
		LeaderStats: stats.NewLeaderStats(strconv.Itoa(rc.id)),
		ErrorC:      make(chan error),
	}

	rc.transport.Start()
	for i := range rc.peers {
		if i+1 != rc.id {
			rc.transport.AddPeer(types.ID(i+1), []string{rc.peers[i]})
		}
	}

	go rc.serveRaft()
	go rc.serveChannels()
}

// stop closes http, closes all channels, and stops raft.
func (rc *raftNode) stop() {
	rc.stopHTTP()
	close(rc.commitC)
	close(rc.errorC)
	rc.node.Stop()
}

func (rc *raftNode) stopHTTP() {
	rc.transport.Stop()
	close(rc.httpstopc)
	<-rc.httpdonec
}

func (rc *raftNode) serveChannels() {
	defer rc.wal.Close()

	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	// send proposals over raft
	go func() {
		for prop := range rc.proposeC {
			// blocks until accepted by raft state machine
			rc.node.Propose(context.TODO(), []byte(prop))
		}
		// client closed channel; shutdown raft if not already
		close(rc.stopc)
	}()

	// event loop on raft state machine updates
	for {
		select {
		case <-ticker.C:
			rc.node.Tick()

		// store raft entries to wal, then publish over commit channel
		case rd := <-rc.node.Ready():
			rc.wal.Save(rd.HardState, rd.Entries)
			rc.raftStorage.Append(rd.Entries)
			rc.transport.Send(rd.Messages)
			if ok := rc.publishEntries(rd.Entries); !ok {
				rc.stop()
				return
			}
			rc.node.Advance()

		case err := <-rc.transport.ErrorC:
			rc.writeError(err)
			return

		case <-rc.stopc:
			rc.stop()
			return
		}
	}
}

func (rc *raftNode) serveRaft() {
	url, err := url.Parse(rc.peers[rc.id-1])
	if err != nil {
		log.Fatalf("raftexample: Failed parsing URL (%v)", err)
	}

	ln, err := newStoppableListener(url.Host, rc.httpstopc)
	if err != nil {
		log.Fatalf("raftexample: Failed to listen rafthttp (%v)", err)
	}

	err = (&http.Server{Handler: rc.transport.Handler()}).Serve(ln)
	select {
	case <-rc.httpstopc:
	default:
		log.Fatalf("raftexample: Failed to serve rafthttp (%v)", err)
	}
	close(rc.httpdonec)
}

func (rc *raftNode) Process(ctx context.Context, m raftpb.Message) error {
	return rc.node.Step(ctx, m)
}
func (rc *raftNode) IsIDRemoved(id uint64) bool                           { return false }
func (rc *raftNode) ReportUnreachable(id uint64)                          {}
func (rc *raftNode) ReportSnapshot(id uint64, status raft.SnapshotStatus) {}
