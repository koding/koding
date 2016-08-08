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

package v3rpc

import (
	"github.com/coreos/etcd/Godeps/_workspace/src/google.golang.org/grpc"
	"github.com/coreos/etcd/Godeps/_workspace/src/google.golang.org/grpc/codes"
	"github.com/coreos/etcd/storage"
)

var (
	ErrEmptyKey      = grpc.Errorf(codes.InvalidArgument, "key is not provided")
	ErrTooManyOps    = grpc.Errorf(codes.InvalidArgument, "too many operations in txn request")
	ErrCompacted     = grpc.Errorf(codes.OutOfRange, storage.ErrCompacted.Error())
	ErrFutureRev     = grpc.Errorf(codes.OutOfRange, storage.ErrFutureRev.Error())
	ErrLeaseNotFound = grpc.Errorf(codes.NotFound, "requested lease not found")

	ErrMemberExist    = grpc.Errorf(codes.FailedPrecondition, "member ID already exist")
	ErrPeerURLExist   = grpc.Errorf(codes.FailedPrecondition, "Peer URLs already exists")
	ErrMemberBadURLs  = grpc.Errorf(codes.InvalidArgument, "given member URLs are invalid")
	ErrMemberNotFound = grpc.Errorf(codes.NotFound, "member not found")
)
