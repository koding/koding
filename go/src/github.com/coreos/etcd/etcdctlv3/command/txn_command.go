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
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/coreos/etcd/Godeps/_workspace/src/github.com/spf13/cobra"
	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	"github.com/coreos/etcd/clientv3"
)

var (
	txnInteractive bool
)

// NewTxnCommand returns the cobra command for "txn".
func NewTxnCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "txn [options]",
		Short: "Txn processes all the requests in one transaction.",
		Run:   txnCommandFunc,
	}
	cmd.Flags().BoolVarP(&txnInteractive, "interactive", "i", false, "input transaction in interactive mode")
	return cmd
}

// txnCommandFunc executes the "txn" command.
func txnCommandFunc(cmd *cobra.Command, args []string) {
	if len(args) != 0 {
		ExitWithError(ExitBadArgs, fmt.Errorf("txn command does not accept argument."))
	}

	if !txnInteractive {
		ExitWithError(ExitBadFeature, fmt.Errorf("txn command only supports interactive mode"))
	}

	reader := bufio.NewReader(os.Stdin)

	txn := mustClientFromCmd(cmd).Txn(context.Background())
	fmt.Println("compares:")
	txn.If(readCompares(reader)...)
	fmt.Println("success requests (get, put, delete):")
	txn.Then(readOps(reader)...)
	fmt.Println("failure requests (get, put, delete):")
	txn.Else(readOps(reader)...)

	resp, err := txn.Commit()
	if err != nil {
		ExitWithError(ExitError, err)
	}

	display.Txn(*resp)
}

func readCompares(r *bufio.Reader) (cmps []clientv3.Cmp) {
	for {
		line, err := r.ReadString('\n')
		if err != nil {
			ExitWithError(ExitInvalidInput, err)
		}
		if len(line) == 1 {
			break
		}

		// remove trialling \n
		line = line[:len(line)-1]
		cmp, err := parseCompare(line)
		if err != nil {
			ExitWithError(ExitInvalidInput, err)
		}
		cmps = append(cmps, *cmp)
	}

	return cmps
}

func readOps(r *bufio.Reader) (ops []clientv3.Op) {
	for {
		line, err := r.ReadString('\n')
		if err != nil {
			ExitWithError(ExitInvalidInput, err)
		}
		if len(line) == 1 {
			break
		}

		// remove trialling \n
		line = line[:len(line)-1]
		op, err := parseRequestUnion(line)
		if err != nil {
			ExitWithError(ExitInvalidInput, err)
		}
		ops = append(ops, *op)
	}

	return ops
}

func parseRequestUnion(line string) (*clientv3.Op, error) {
	args := argify(line)
	if len(args) < 2 {
		return nil, fmt.Errorf("invalid txn compare request: %s", line)
	}

	opc := make(chan clientv3.Op, 1)

	put := NewPutCommand()
	put.Run = func(cmd *cobra.Command, args []string) {
		key, value, opts := getPutOp(cmd, args)
		opc <- clientv3.OpPut(key, value, opts...)
	}
	get := NewGetCommand()
	get.Run = func(cmd *cobra.Command, args []string) {
		key, opts := getGetOp(cmd, args)
		opc <- clientv3.OpGet(key, opts...)
	}
	del := NewDelCommand()
	del.Run = func(cmd *cobra.Command, args []string) {
		key, opts := getDelOp(cmd, args)
		opc <- clientv3.OpDelete(key, opts...)
	}
	cmds := &cobra.Command{SilenceErrors: true}
	cmds.AddCommand(put, get, del)

	cmds.SetArgs(args)
	if err := cmds.Execute(); err != nil {
		return nil, fmt.Errorf("invalid txn request: %s", line)
	}

	op := <-opc
	return &op, nil
}

func parseCompare(line string) (*clientv3.Cmp, error) {
	var (
		key string
		op  string
		val string
	)

	lparenSplit := strings.SplitN(line, "(", 2)
	if len(lparenSplit) != 2 {
		return nil, fmt.Errorf("malformed comparison: %s", line)
	}

	target := lparenSplit[0]
	n, serr := fmt.Sscanf(lparenSplit[1], "%q) %s %q", &key, &op, &val)
	if n != 3 {
		return nil, fmt.Errorf("malformed comparison: %s; got %s(%q) %s %q", line, target, key, op, val)
	}
	if serr != nil {
		return nil, fmt.Errorf("malformed comparison: %s (%v)", line, serr)
	}

	var (
		v   int64
		err error
		cmp clientv3.Cmp
	)
	switch target {
	case "ver", "version":
		if v, err = strconv.ParseInt(val, 10, 64); err == nil {
			cmp = clientv3.Compare(clientv3.Version(key), op, v)
		}
	case "c", "create":
		if v, err = strconv.ParseInt(val, 10, 64); err == nil {
			cmp = clientv3.Compare(clientv3.CreatedRevision(key), op, v)
		}
	case "m", "mod":
		if v, err = strconv.ParseInt(val, 10, 64); err == nil {
			cmp = clientv3.Compare(clientv3.ModifiedRevision(key), op, v)
		}
	case "val", "value":
		cmp = clientv3.Compare(clientv3.Value(key), op, val)
	default:
		return nil, fmt.Errorf("malformed comparison: %s (unknown target %s)", line, target)
	}

	if err != nil {
		return nil, fmt.Errorf("invalid txn compare request: %s", line)
	}

	return &cmp, nil
}
