// Copyright 2015 Google Inc. All Rights Reserved.
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

package statfs_test

import (
	"fmt"
	"math"
	"regexp"
	"syscall"

	"github.com/jacobsa/fuse/fuseops"
	. "github.com/jacobsa/ogletest"
)

// Sample output:
//
//     Filesystem  1024-blocks Used Available Capacity iused ifree %iused  Mounted on
//     fake@bucket          32   16        16    50%       0     0  100%   /Users/jacobsa/tmp/mp
//
var gDfOutputRegexp = regexp.MustCompile(`^\S+\s+(\d+)\s+(\d+)\s+(\d+)\s+\d+%\s+\d+\s+\d+\s+\d+%.*$`)

////////////////////////////////////////////////////////////////////////
// Helpers
////////////////////////////////////////////////////////////////////////

func convertName(in []int8) (s string) {
	var tmp []byte
	for _, v := range in {
		if v == 0 {
			break
		}

		tmp = append(tmp, byte(v))
	}

	s = string(tmp)
	return
}

////////////////////////////////////////////////////////////////////////
// Tests
////////////////////////////////////////////////////////////////////////

func (t *StatFSTest) Syscall_ZeroValues() {
	var err error
	var stat syscall.Statfs_t

	// Call without configuring a canned response, meaning the OS will see the
	// zero value for each field. The assertions below act as documentation for
	// the OS's behavior in this case.
	err = syscall.Statfs(t.Dir, &stat)
	AssertEq(nil, err)

	ExpectEq(4096, stat.Bsize)
	ExpectEq(65536, stat.Iosize)
	ExpectEq(0, stat.Blocks)
	ExpectEq(0, stat.Bfree)
	ExpectEq(0, stat.Bavail)
	ExpectEq(0, stat.Files)
	ExpectEq(0, stat.Ffree)
	ExpectEq("osxfusefs", convertName(stat.Fstypename[:]))
	ExpectEq(t.canonicalDir, convertName(stat.Mntonname[:]))
	ExpectEq(fsName, convertName(stat.Mntfromname[:]))
}

func (t *StatFSTest) Syscall_NonZeroValues() {
	var err error
	var stat syscall.Statfs_t

	// Set up the canned response.
	canned := fuseops.StatFSOp{
		BlockSize: 1 << 15,
		IoSize:    1 << 16,

		Blocks:          1<<51 + 3,
		BlocksFree:      1<<43 + 5,
		BlocksAvailable: 1<<41 + 7,

		Inodes:     1<<59 + 11,
		InodesFree: 1<<58 + 13,
	}

	t.fs.SetStatFSResponse(canned)

	// Stat.
	err = syscall.Statfs(t.Dir, &stat)
	AssertEq(nil, err)

	ExpectEq(canned.BlockSize, stat.Bsize)
	ExpectEq(canned.IoSize, stat.Iosize)
	ExpectEq(canned.Blocks, stat.Blocks)
	ExpectEq(canned.BlocksFree, stat.Bfree)
	ExpectEq(canned.BlocksAvailable, stat.Bavail)
	ExpectEq(canned.Inodes, stat.Files)
	ExpectEq(canned.InodesFree, stat.Ffree)
	ExpectEq("osxfusefs", convertName(stat.Fstypename[:]))
	ExpectEq(t.canonicalDir, convertName(stat.Mntonname[:]))
	ExpectEq(fsName, convertName(stat.Mntfromname[:]))
}

func (t *StatFSTest) BlockSizes() {
	var err error

	// Test a bunch of block sizes that the OS does or doesn't support
	// faithfully, checking what it transforms them too.
	testCases := []struct {
		fsBlockSize   uint32
		expectedBsize uint32
	}{
		0:  {0, 4096},
		1:  {1, 512},
		2:  {3, 512},
		3:  {511, 512},
		4:  {512, 512},
		5:  {513, 1024},
		6:  {1023, 1024},
		7:  {1024, 1024},
		8:  {4095, 4096},
		9:  {1 << 16, 1 << 16},
		10: {1<<17 - 1, 1 << 17},
		11: {1 << 17, 1 << 17},
		12: {1<<17 + 1, 1 << 17},
		13: {1 << 18, 1 << 17},
		14: {1 << 20, 1 << 17},
		15: {math.MaxInt32 - 1, 1 << 17},
		16: {math.MaxInt32, 1 << 17},
		17: {math.MaxInt32 + 1, 512},
		18: {math.MaxInt32 + 1<<15, 1 << 15},
		19: {math.MaxUint32, 1 << 17},
	}

	for i, tc := range testCases {
		desc := fmt.Sprintf("Case %d: block size %d", i, tc.fsBlockSize)

		// Set up.
		canned := fuseops.StatFSOp{
			BlockSize: tc.fsBlockSize,
			Blocks:    10,
		}

		t.fs.SetStatFSResponse(canned)

		// Check.
		var stat syscall.Statfs_t
		err = syscall.Statfs(t.Dir, &stat)
		AssertEq(nil, err)

		ExpectEq(tc.expectedBsize, stat.Bsize, "%s", desc)
	}
}

func (t *StatFSTest) IoSizes() {
	var err error

	// Test a bunch of io sizes that the OS does or doesn't support faithfully,
	// checking what it transforms them too.
	testCases := []struct {
		fsIoSize       uint32
		expectedIosize uint32
	}{
		0:  {0, 65536},
		1:  {1, 4096},
		2:  {3, 4096},
		3:  {4095, 4096},
		4:  {4096, 4096},
		5:  {4097, 8192},
		6:  {8191, 8192},
		7:  {8192, 8192},
		8:  {8193, 16384},
		9:  {1<<20 - 1, 1 << 20},
		10: {1 << 20, 1 << 20},
		11: {1<<20 + 1, 1 << 20},
		12: {math.MaxInt32 - 1, 1 << 20},
		13: {math.MaxInt32, 1 << 20},
		14: {math.MaxInt32 + 1, 4096},
		15: {math.MaxInt32 + 1<<15, 1 << 15},
		16: {math.MaxUint32, 1 << 20},
	}

	for i, tc := range testCases {
		desc := fmt.Sprintf("Case %d: IO size %d", i, tc.fsIoSize)

		// Set up.
		canned := fuseops.StatFSOp{
			IoSize: tc.fsIoSize,
			Blocks: 10,
		}

		t.fs.SetStatFSResponse(canned)

		// Check.
		var stat syscall.Statfs_t
		err = syscall.Statfs(t.Dir, &stat)
		AssertEq(nil, err)

		ExpectEq(tc.expectedIosize, stat.Iosize, "%s", desc)
	}
}
