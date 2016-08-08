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

package command

import (
	"github.com/coreos/etcd/Godeps/_workspace/src/github.com/spf13/cobra"
	"github.com/coreos/etcd/clientv3"
)

// GlobalFlags are flags that defined globally
// and are inherited to all sub-commands.
type GlobalFlags struct {
	Endpoints string
}

func mustClient(cmd *cobra.Command) *clientv3.Client {
	endpoint, err := cmd.Flags().GetString("endpoint")
	if err != nil {
		ExitWithError(ExitError, err)
	}
	client, err := clientv3.NewFromURL(endpoint)
	if err != nil {
		ExitWithError(ExitBadConnection, err)
	}
	return client
}
