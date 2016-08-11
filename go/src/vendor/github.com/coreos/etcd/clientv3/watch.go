// Copyright 2016 CoreOS, Inc.
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

package clientv3

import (
	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	pb "github.com/coreos/etcd/etcdserver/etcdserverpb"
	storagepb "github.com/coreos/etcd/storage/storagepb"
)

type Watcher interface {
	// Watch watches on a single key. The watched events will be returned
	// through the returned channel.
	// If the watch is slow or the required rev is compacted, the watch request
	// might be canceled from the server-side and the chan will be closed.
	Watch(cxt context.Context, key string, rev int64) <-chan WatchResponse

	// Watch watches on a prefix. The watched events will be returned
	// through the returned channel.
	// If the watch is slow or the required rev is compacted, the watch request
	// might be canceled from the server-side and the chan will be closed.
	WatchPrefix(cxt context.Context, prefix string, rev int64) <-chan WatchResponse

	// Close closes the watcher and cancels all watch requests.
	Close() error
}

type WatchResponse struct {
	Header pb.ResponseHeader
	Events []*storagepb.Event
}
