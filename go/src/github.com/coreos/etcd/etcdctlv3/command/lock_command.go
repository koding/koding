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

package command

import (
	"errors"
	"os"
	"os/signal"

	"github.com/coreos/etcd/Godeps/_workspace/src/github.com/spf13/cobra"
	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	"github.com/coreos/etcd/clientv3"
	"github.com/coreos/etcd/clientv3/concurrency"
)

// NewLockCommand returns the cobra command for "lock".
func NewLockCommand() *cobra.Command {
	c := &cobra.Command{
		Use:   "lock <lockname>",
		Short: "lock acquires a named lock",
		Run:   lockCommandFunc,
	}
	return c
}

func lockCommandFunc(cmd *cobra.Command, args []string) {
	if len(args) != 1 {
		ExitWithError(ExitBadArgs, errors.New("lock takes one lock name arguement."))
	}
	c := mustClientFromCmd(cmd)
	if err := lockUntilSignal(c, args[0]); err != nil {
		ExitWithError(ExitError, err)
	}
}

func lockUntilSignal(c *clientv3.Client, lockname string) error {
	m := concurrency.NewMutex(context.TODO(), c, lockname)
	ctx, cancel := context.WithCancel(context.TODO())

	// unlock in case of ordinary shutdown
	donec := make(chan struct{})
	sigc := make(chan os.Signal, 1)
	signal.Notify(sigc, os.Interrupt, os.Kill)
	go func() {
		<-sigc
		cancel()
		close(donec)
	}()

	s, serr := concurrency.NewSession(c)
	if serr != nil {
		return serr
	}

	if err := m.Lock(ctx); err != nil {
		return err
	}

	k, kerr := c.Get(ctx, m.Key())
	if kerr != nil {
		return kerr
	}
	if len(k.Kvs) == 0 {
		return errors.New("lock lost on init")
	}

	display.Get(*k)

	select {
	case <-donec:
		return m.Unlock()
	case <-s.Done():
	}

	return errors.New("session expired")
}
