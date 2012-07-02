/**
 * Test Harness for Diff Match and Patch
 *
 * Copyright 2006 Google Inc.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*CHANGED BY lfborjas:
    using the module conventions of node and also changed the use of the original author's assert functions
    by using the `assert` module included with node.js. Therefore, wherever assertEquals or assertEquivalent
    were called, now you'll find calls to assert.equal and assert.deepEqual, respectively.

    Also, added the script that was in the original html test to print what tests are being called in console.

    If a test fails, an exception will be raised.    
*/
assert = require('assert');
dmp_mod = require('../lib/diff_match_patch.js');
sys = require("sys");
var DIFF_INSERT = dmp_mod.DIFF_INSERT;
var DIFF_DELETE = dmp_mod.DIFF_DELETE;
var DIFF_EQUAL = dmp_mod.DIFF_EQUAL;
var patch_obj = dmp_mod.patch_obj;
// If expected and actual are the equivalent, pass the test.
function assertEquivalent(msg, expected, actual) {
  if (typeof actual == 'undefined') {
    // msg is optional.
    actual = expected;
    expected = msg;
    msg = 'Expected: \'' + expected + '\' Actual: \'' + actual + '\'';
  }
  if (_equivalent(expected, actual)) {
    assert.equal(msg, String.toString(expected), String.toString(actual));
  } else {
    assert.equal(msg, expected, actual);
  }
}


// Are a and b the equivalent? -- Recursive.
function _equivalent(a, b) {
  if (a == b) {
    return true;
  }
  if (typeof a == 'object' && typeof b == 'object' && a !== null && b !== null) {
    if (a.toString() != b.toString()) {
      return false;
    }
    for (var p in a) {
      if (!_equivalent(a[p], b[p])) {
        return false;
      }
    }
    for (var p in b) {
      if (!_equivalent(a[p], b[p])) {
        return false;
      }
    }
    return true;
  }
  return false;
}


function diff_rebuildtexts(diffs) {
  // Construct the two texts which made up the diff originally.
  var text1 = '';
  var text2 = '';
  for (var x = 0; x < diffs.length; x++) {
    if (diffs[x][0] != DIFF_INSERT) {
      text1 += diffs[x][1];
    }
    if (diffs[x][0] != DIFF_DELETE) {
      text2 += diffs[x][1];
    }
  }
  return [text1, text2];
}

var dmp = new dmp_mod.diff_match_patch();


// DIFF TEST FUNCTIONS


function testDiffCommonPrefix() {
  // Detect and remove any common prefix.
  // Null case.
  assert.equal(0, dmp.diff_commonPrefix('abc', 'xyz'));

  // Non-null case.
  assert.equal(4, dmp.diff_commonPrefix('1234abcdef', '1234xyz'));

  // Whole case.
  assert.equal(4, dmp.diff_commonPrefix('1234', '1234xyz'));
}

function testDiffCommonSuffix() {
  // Detect and remove any common suffix.
  // Null case.
  assert.equal(0, dmp.diff_commonSuffix('abc', 'xyz'));

  // Non-null case.
  assert.equal(4, dmp.diff_commonSuffix('abcdef1234', 'xyz1234'));

  // Whole case.
  assert.equal(4, dmp.diff_commonSuffix('1234', 'xyz1234'));
}

function testDiffHalfMatch() {
  // Detect a halfmatch.
  // No match.
  assert.equal(null, dmp.diff_halfMatch('1234567890', 'abcdef'));

  // Single Match.
  assert.deepEqual(['12', '90', 'a', 'z', '345678'], dmp.diff_halfMatch('1234567890', 'a345678z'));

  assert.deepEqual(['a', 'z', '12', '90', '345678'], dmp.diff_halfMatch('a345678z', '1234567890'));

  // Multiple Matches.
  assert.deepEqual(['12123', '123121', 'a', 'z', '1234123451234'], dmp.diff_halfMatch('121231234123451234123121', 'a1234123451234z'));

  assert.deepEqual(['', '-=-=-=-=-=', 'x', '', 'x-=-=-=-=-=-=-='], dmp.diff_halfMatch('x-=-=-=-=-=-=-=-=-=-=-=-=', 'xx-=-=-=-=-=-=-='));

  assert.deepEqual(['-=-=-=-=-=', '', '', 'y', '-=-=-=-=-=-=-=y'], dmp.diff_halfMatch('-=-=-=-=-=-=-=-=-=-=-=-=y', '-=-=-=-=-=-=-=yy'));
}

function testDiffLinesToChars() {
  // Convert lines down to characters.
  assert.deepEqual(['\x01\x02\x01', '\x02\x01\x02', ['', 'alpha\n', 'beta\n']], dmp.diff_linesToChars('alpha\nbeta\nalpha\n', 'beta\nalpha\nbeta\n'));

  assert.deepEqual(['', '\x01\x02\x03\x03', ['', 'alpha\r\n', 'beta\r\n', '\r\n']], dmp.diff_linesToChars('', 'alpha\r\nbeta\r\n\r\n\r\n'));

  assert.deepEqual(['\x01', '\x02', ['', 'a', 'b']], dmp.diff_linesToChars('a', 'b'));

  // More than 256 to reveal any 8-bit limitations.
  var n = 300;
  var lineList = [];
  var charList = [];
  for (var x = 1; x < n + 1; x++) {
    lineList[x - 1] = x + '\n';
    charList[x - 1] = String.fromCharCode(x);
  }
  assert.equal(n, lineList.length);
  var lines = lineList.join('');
  var chars = charList.join('');
  assert.equal(n, chars.length);
  lineList.unshift('');
  assert.deepEqual([chars, '', lineList], dmp.diff_linesToChars(lines, ''));
}

function testDiffCharsToLines() {
  // Convert chars up to lines.
  var diffs = [[DIFF_EQUAL, '\x01\x02\x01'], [DIFF_INSERT, '\x02\x01\x02']];
  dmp.diff_charsToLines(diffs, ['', 'alpha\n', 'beta\n']);
  assert.deepEqual([[DIFF_EQUAL, 'alpha\nbeta\nalpha\n'], [DIFF_INSERT, 'beta\nalpha\nbeta\n']], diffs);

  // More than 256 to reveal any 8-bit limitations.
  var n = 300;
  var lineList = [];
  var charList = [];
  for (var x = 1; x < n + 1; x++) {
    lineList[x - 1] = x + '\n';
    charList[x - 1] = String.fromCharCode(x);
  }
  assert.equal(n, lineList.length);
  var lines = lineList.join('');
  var chars = charList.join('');
  assert.equal(n, chars.length);
  lineList.unshift('');
  var diffs = [[DIFF_DELETE, chars]];
  dmp.diff_charsToLines(diffs, lineList);
  assert.deepEqual([[DIFF_DELETE, lines]], diffs);
}

function testDiffCleanupMerge() {
  // Cleanup a messy diff.
  // Null case.
  var diffs = [];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([], diffs);

  // No change case.
  diffs = [[DIFF_EQUAL, 'a'], [DIFF_DELETE, 'b'], [DIFF_INSERT, 'c']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'a'], [DIFF_DELETE, 'b'], [DIFF_INSERT, 'c']], diffs);

  // Merge equalities.
  diffs = [[DIFF_EQUAL, 'a'], [DIFF_EQUAL, 'b'], [DIFF_EQUAL, 'c']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'abc']], diffs);

  // Merge deletions.
  diffs = [[DIFF_DELETE, 'a'], [DIFF_DELETE, 'b'], [DIFF_DELETE, 'c']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_DELETE, 'abc']], diffs);

  // Merge insertions.
  diffs = [[DIFF_INSERT, 'a'], [DIFF_INSERT, 'b'], [DIFF_INSERT, 'c']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_INSERT, 'abc']], diffs);

  // Merge interweave.
  diffs = [[DIFF_DELETE, 'a'], [DIFF_INSERT, 'b'], [DIFF_DELETE, 'c'], [DIFF_INSERT, 'd'], [DIFF_EQUAL, 'e'], [DIFF_EQUAL, 'f']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_DELETE, 'ac'], [DIFF_INSERT, 'bd'], [DIFF_EQUAL, 'ef']], diffs);

  // Prefix and suffix detection.
  diffs = [[DIFF_DELETE, 'a'], [DIFF_INSERT, 'abc'], [DIFF_DELETE, 'dc']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'a'], [DIFF_DELETE, 'd'], [DIFF_INSERT, 'b'], [DIFF_EQUAL, 'c']], diffs);

  // Slide edit left.
  diffs = [[DIFF_EQUAL, 'a'], [DIFF_INSERT, 'ba'], [DIFF_EQUAL, 'c']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_INSERT, 'ab'], [DIFF_EQUAL, 'ac']], diffs);

  // Slide edit right.
  diffs = [[DIFF_EQUAL, 'c'], [DIFF_INSERT, 'ab'], [DIFF_EQUAL, 'a']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'ca'], [DIFF_INSERT, 'ba']], diffs);

  // Slide edit left recursive.
  diffs = [[DIFF_EQUAL, 'a'], [DIFF_DELETE, 'b'], [DIFF_EQUAL, 'c'], [DIFF_DELETE, 'ac'], [DIFF_EQUAL, 'x']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_DELETE, 'abc'], [DIFF_EQUAL, 'acx']], diffs);

  // Slide edit right recursive.
  diffs = [[DIFF_EQUAL, 'x'], [DIFF_DELETE, 'ca'], [DIFF_EQUAL, 'c'], [DIFF_DELETE, 'b'], [DIFF_EQUAL, 'a']];
  dmp.diff_cleanupMerge(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'xca'], [DIFF_DELETE, 'cba']], diffs);
}

function testDiffCleanupSemanticLossless() {
  // Slide diffs to match logical boundaries.
  // Null case.
  var diffs = [];
  dmp.diff_cleanupSemanticLossless(diffs);
  assert.deepEqual([], diffs);

  // Blank lines.
  diffs = [[DIFF_EQUAL, 'AAA\r\n\r\nBBB'], [DIFF_INSERT, '\r\nDDD\r\n\r\nBBB'], [DIFF_EQUAL, '\r\nEEE']];
  dmp.diff_cleanupSemanticLossless(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'AAA\r\n\r\n'], [DIFF_INSERT, 'BBB\r\nDDD\r\n\r\n'], [DIFF_EQUAL, 'BBB\r\nEEE']], diffs);

  // Line boundaries.
  diffs = [[DIFF_EQUAL, 'AAA\r\nBBB'], [DIFF_INSERT, ' DDD\r\nBBB'], [DIFF_EQUAL, ' EEE']];
  dmp.diff_cleanupSemanticLossless(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'AAA\r\n'], [DIFF_INSERT, 'BBB DDD\r\n'], [DIFF_EQUAL, 'BBB EEE']], diffs);

  // Word boundaries.
  diffs = [[DIFF_EQUAL, 'The c'], [DIFF_INSERT, 'ow and the c'], [DIFF_EQUAL, 'at.']];
  dmp.diff_cleanupSemanticLossless(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'The '], [DIFF_INSERT, 'cow and the '], [DIFF_EQUAL, 'cat.']], diffs);

  // Alphanumeric boundaries.
  diffs = [[DIFF_EQUAL, 'The-c'], [DIFF_INSERT, 'ow-and-the-c'], [DIFF_EQUAL, 'at.']];
  dmp.diff_cleanupSemanticLossless(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'The-'], [DIFF_INSERT, 'cow-and-the-'], [DIFF_EQUAL, 'cat.']], diffs);

  // Hitting the start.
  diffs = [[DIFF_EQUAL, 'a'], [DIFF_DELETE, 'a'], [DIFF_EQUAL, 'ax']];
  dmp.diff_cleanupSemanticLossless(diffs);
  assert.deepEqual([[DIFF_DELETE, 'a'], [DIFF_EQUAL, 'aax']], diffs);

  // Hitting the end.
  diffs = [[DIFF_EQUAL, 'xa'], [DIFF_DELETE, 'a'], [DIFF_EQUAL, 'a']];
  dmp.diff_cleanupSemanticLossless(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'xaa'], [DIFF_DELETE, 'a']], diffs);
}

function testDiffCleanupSemantic() {
  // Cleanup semantically trivial equalities.
  // Null case.
  var diffs = [];
  dmp.diff_cleanupSemantic(diffs);
  assert.deepEqual([], diffs);

  // No elimination.
  diffs = [[DIFF_DELETE, 'a'], [DIFF_INSERT, 'b'], [DIFF_EQUAL, 'cd'], [DIFF_DELETE, 'e']];
  dmp.diff_cleanupSemantic(diffs);
  assert.deepEqual([[DIFF_DELETE, 'a'], [DIFF_INSERT, 'b'], [DIFF_EQUAL, 'cd'], [DIFF_DELETE, 'e']], diffs);

  // Simple elimination.
  diffs = [[DIFF_DELETE, 'a'], [DIFF_EQUAL, 'b'], [DIFF_DELETE, 'c']];
  dmp.diff_cleanupSemantic(diffs);
  assert.deepEqual([[DIFF_DELETE, 'abc'], [DIFF_INSERT, 'b']], diffs);

  // Backpass elimination.
  diffs = [[DIFF_DELETE, 'ab'], [DIFF_EQUAL, 'cd'], [DIFF_DELETE, 'e'], [DIFF_EQUAL, 'f'], [DIFF_INSERT, 'g']];
  dmp.diff_cleanupSemantic(diffs);
  assert.deepEqual([[DIFF_DELETE, 'abcdef'], [DIFF_INSERT, 'cdfg']], diffs);

  // Multiple eliminations.
  diffs = [[DIFF_INSERT, '1'], [DIFF_EQUAL, 'A'], [DIFF_DELETE, 'B'], [DIFF_INSERT, '2'], [DIFF_EQUAL, '_'], [DIFF_INSERT, '1'], [DIFF_EQUAL, 'A'], [DIFF_DELETE, 'B'], [DIFF_INSERT, '2']];
  dmp.diff_cleanupSemantic(diffs);
  assert.deepEqual([[DIFF_DELETE, 'AB_AB'], [DIFF_INSERT, '1A2_1A2']], diffs);

  // Word boundaries.
  diffs = [[DIFF_EQUAL, 'The c'], [DIFF_DELETE, 'ow and the c'], [DIFF_EQUAL, 'at.']];
  dmp.diff_cleanupSemantic(diffs);
  assert.deepEqual([[DIFF_EQUAL, 'The '], [DIFF_DELETE, 'cow and the '], [DIFF_EQUAL, 'cat.']], diffs);
}

function testDiffCleanupEfficiency() {
  // Cleanup operationally trivial equalities.
  dmp.Diff_EditCost = 4;
  // Null case.
  var diffs = [];
  dmp.diff_cleanupEfficiency(diffs);
  assert.deepEqual([], diffs);

  // No elimination.
  diffs = [[DIFF_DELETE, 'ab'], [DIFF_INSERT, '12'], [DIFF_EQUAL, 'wxyz'], [DIFF_DELETE, 'cd'], [DIFF_INSERT, '34']];
  dmp.diff_cleanupEfficiency(diffs);
  assert.deepEqual([[DIFF_DELETE, 'ab'], [DIFF_INSERT, '12'], [DIFF_EQUAL, 'wxyz'], [DIFF_DELETE, 'cd'], [DIFF_INSERT, '34']], diffs);

  // Four-edit elimination.
  diffs = [[DIFF_DELETE, 'ab'], [DIFF_INSERT, '12'], [DIFF_EQUAL, 'xyz'], [DIFF_DELETE, 'cd'], [DIFF_INSERT, '34']];
  dmp.diff_cleanupEfficiency(diffs);
  assert.deepEqual([[DIFF_DELETE, 'abxyzcd'], [DIFF_INSERT, '12xyz34']], diffs);

  // Three-edit elimination.
  diffs = [[DIFF_INSERT, '12'], [DIFF_EQUAL, 'x'], [DIFF_DELETE, 'cd'], [DIFF_INSERT, '34']];
  dmp.diff_cleanupEfficiency(diffs);
  assert.deepEqual([[DIFF_DELETE, 'xcd'], [DIFF_INSERT, '12x34']], diffs);

  // Backpass elimination.
  diffs = [[DIFF_DELETE, 'ab'], [DIFF_INSERT, '12'], [DIFF_EQUAL, 'xy'], [DIFF_INSERT, '34'], [DIFF_EQUAL, 'z'], [DIFF_DELETE, 'cd'], [DIFF_INSERT, '56']];
  dmp.diff_cleanupEfficiency(diffs);
  assert.deepEqual([[DIFF_DELETE, 'abxyzcd'], [DIFF_INSERT, '12xy34z56']], diffs);

  // High cost elimination.
  dmp.Diff_EditCost = 5;
  diffs = [[DIFF_DELETE, 'ab'], [DIFF_INSERT, '12'], [DIFF_EQUAL, 'wxyz'], [DIFF_DELETE, 'cd'], [DIFF_INSERT, '34']];
  dmp.diff_cleanupEfficiency(diffs);
  assert.deepEqual([[DIFF_DELETE, 'abwxyzcd'], [DIFF_INSERT, '12wxyz34']], diffs);
  dmp.Diff_EditCost = 4;
}

function testDiffPrettyHtml() {
  // Pretty print.
  var diffs = [[DIFF_EQUAL, 'a\n'], [DIFF_DELETE, '<B>b</B>'], [DIFF_INSERT, 'c&d']];
  assert.equal('<SPAN TITLE="i=0">a&para;<BR></SPAN><DEL STYLE="background:#FFE6E6;" TITLE="i=2">&lt;B&gt;b&lt;/B&gt;</DEL><INS STYLE="background:#E6FFE6;" TITLE="i=2">c&amp;d</INS>', dmp.diff_prettyHtml(diffs));
}

function testDiffText() {
  // Compute the source and destination texts.
  var diffs = [[DIFF_EQUAL, 'jump'], [DIFF_DELETE, 's'], [DIFF_INSERT, 'ed'], [DIFF_EQUAL, ' over '], [DIFF_DELETE, 'the'], [DIFF_INSERT, 'a'], [DIFF_EQUAL, ' lazy']];
  assert.equal('jumps over the lazy', dmp.diff_text1(diffs));

  assert.equal('jumped over a lazy', dmp.diff_text2(diffs));
}

function testDiffDelta() {
  // Convert a diff into delta string.
  var diffs = [[DIFF_EQUAL, 'jump'], [DIFF_DELETE, 's'], [DIFF_INSERT, 'ed'], [DIFF_EQUAL, ' over '], [DIFF_DELETE, 'the'], [DIFF_INSERT, 'a'], [DIFF_EQUAL, ' lazy'], [DIFF_INSERT, 'old dog']];
  var text1 = dmp.diff_text1(diffs);
  assert.equal('jumps over the lazy', text1);

  var delta = dmp.diff_toDelta(diffs);
  assert.equal('=4\t-1\t+ed\t=6\t-3\t+a\t=5\t+old dog', delta);

  // Convert delta string into a diff.
  assert.deepEqual(diffs, dmp.diff_fromDelta(text1, delta));

  // Generates error (19 != 20).
  try {
    dmp.diff_fromDelta(text1 + 'x', delta);
    assert.equal(Error, null);
  } catch (e) {
    // Exception expected.
  }

  // Generates error (19 != 18).
  try {
    dmp.diff_fromDelta(text1.substring(1), delta);
    assert.equal(Error, null);
  } catch (e) {
    // Exception expected.
  }

  // Generates error (%c3%xy invalid Unicode).
  try {
    dmp.diff_fromDelta('', '+%c3%xy');
    assert.equal(Error, null);
  } catch (e) {
    // Exception expected.
  }

  // Test deltas with special characters.
  diffs = [[DIFF_EQUAL, '\u0680 \x00 \t %'], [DIFF_DELETE, '\u0681 \x01 \n ^'], [DIFF_INSERT, '\u0682 \x02 \\ |']];
  text1 = dmp.diff_text1(diffs);
  assert.equal('\u0680 \x00 \t %\u0681 \x01 \n ^', text1);

  delta = dmp.diff_toDelta(diffs);
  assert.equal('=7\t-7\t+%DA%82 %02 %5C %7C', delta);

  // Convert delta string into a diff.
  assert.deepEqual(diffs, dmp.diff_fromDelta(text1, delta));

  // Verify pool of unchanged characters.
  diffs = [[DIFF_INSERT, 'A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + $ , # ']];
  var text2 = dmp.diff_text2(diffs);
  assert.equal('A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + $ , # ', text2);

  delta = dmp.diff_toDelta(diffs);
  assert.equal('+A-Z a-z 0-9 - _ . ! ~ * \' ( ) ; / ? : @ & = + $ , # ', delta);

  // Convert delta string into a diff.
  assert.deepEqual(diffs, dmp.diff_fromDelta('', delta));
}

function testDiffXIndex() {
  // Translate a location in text1 to text2.
  // Translation on equality.
  assert.equal(5, dmp.diff_xIndex([[DIFF_DELETE, 'a'], [DIFF_INSERT, '1234'], [DIFF_EQUAL, 'xyz']], 2));

  // Translation on deletion.
  assert.equal(1, dmp.diff_xIndex([[DIFF_EQUAL, 'a'], [DIFF_DELETE, '1234'], [DIFF_EQUAL, 'xyz']], 3));
}

function testDiffLevenshtein() {
  // Levenshtein with trailing equality.
  assert.equal(4, dmp.diff_levenshtein([[DIFF_DELETE, 'abc'], [DIFF_INSERT, '1234'], [DIFF_EQUAL, 'xyz']]));
  // Levenshtein with leading equality.
  assert.equal(4, dmp.diff_levenshtein([[DIFF_EQUAL, 'xyz'], [DIFF_DELETE, 'abc'], [DIFF_INSERT, '1234']]));
  // Levenshtein with middle equality.
  assert.equal(7, dmp.diff_levenshtein([[DIFF_DELETE, 'abc'], [DIFF_EQUAL, 'xyz'], [DIFF_INSERT, '1234']]));
}

function testDiffPath() {
  // Single letters.
  // Trace a path from back to front.
  var v_map = [];
  v_map.push({'0,0':true});
  v_map.push({'0,1':true, '1,0':true});
  v_map.push({'0,2':true, '2,0':true, '2,2':true});
  v_map.push({'0,3':true, '2,3':true, '3,0':true, '4,3':true});
  v_map.push({'0,4':true, '2,4':true, '4,0':true, '4,4':true, '5,3':true});
  v_map.push({'0,5':true, '2,5':true, '4,5':true, '5,0':true, '6,3':true, '6,5':true});
  v_map.push({'0,6':true, '2,6':true, '4,6':true, '6,6':true, '7,5':true});
  assert.deepEqual([[DIFF_INSERT, 'W'], [DIFF_DELETE, 'A'], [DIFF_EQUAL, '1'], [DIFF_DELETE, 'B'], [DIFF_EQUAL, '2'], [DIFF_INSERT, 'X'], [DIFF_DELETE, 'C'], [DIFF_EQUAL, '3'], [DIFF_DELETE, 'D']], dmp.diff_path1(v_map, 'A1B2C3D', 'W12X3'));

  // Trace a path from front to back.
  v_map.pop();
  assert.deepEqual([[DIFF_EQUAL, '4'], [DIFF_DELETE, 'E'], [DIFF_INSERT, 'Y'], [DIFF_EQUAL, '5'], [DIFF_DELETE, 'F'], [DIFF_EQUAL, '6'], [DIFF_DELETE, 'G'], [DIFF_INSERT, 'Z']], dmp.diff_path2(v_map, '4E5F6G', '4Y56Z'));

  // Double letters
  // Trace a path from back to front.
  v_map = [];
  v_map.push({'0,0':true});
  v_map.push({'0,1':true, '1,0':true});
  v_map.push({'0,2':true, '1,1':true, '2,0':true});
  v_map.push({'0,3':true, '1,2':true, '2,1':true, '3,0':true});
  v_map.push({'0,4':true, '1,3':true, '3,1':true, '4,0':true, '4,4':true});
  assert.deepEqual([[DIFF_INSERT, 'WX'], [DIFF_DELETE, 'AB'], [DIFF_EQUAL, '12']], dmp.diff_path1(v_map, 'AB12', 'WX12'));

  // Trace a path from front to back.
  v_map = [];
  v_map.push({'0,0':true});
  v_map.push({'0,1':true, '1,0':true});
  v_map.push({'1,1':true, '2,0':true, '2,4':true});
  v_map.push({'2,1':true, '2,5':true, '3,0':true, '3,4':true});
  v_map.push({'2,6':true, '3,5':true, '4,4':true});
  assert.deepEqual([[DIFF_DELETE, 'CD'], [DIFF_EQUAL, '34'], [DIFF_INSERT, 'YZ']], dmp.diff_path2(v_map, 'CD34', '34YZ'));
}

function testDiffMain() {
  // Perform a trivial diff.
  // Null case.
  assert.deepEqual([[DIFF_EQUAL, 'abc']], dmp.diff_main('abc', 'abc', false));

  // Simple insertion.
  assert.deepEqual([[DIFF_EQUAL, 'ab'], [DIFF_INSERT, '123'], [DIFF_EQUAL, 'c']], dmp.diff_main('abc', 'ab123c', false));

  // Simple deletion.
  assert.deepEqual([[DIFF_EQUAL, 'a'], [DIFF_DELETE, '123'], [DIFF_EQUAL, 'bc']], dmp.diff_main('a123bc', 'abc', false));

  // Two insertions.
  assert.deepEqual([[DIFF_EQUAL, 'a'], [DIFF_INSERT, '123'], [DIFF_EQUAL, 'b'], [DIFF_INSERT, '456'], [DIFF_EQUAL, 'c']], dmp.diff_main('abc', 'a123b456c', false));

  // Two deletions.
  assert.deepEqual([[DIFF_EQUAL, 'a'], [DIFF_DELETE, '123'], [DIFF_EQUAL, 'b'], [DIFF_DELETE, '456'], [DIFF_EQUAL, 'c']], dmp.diff_main('a123b456c', 'abc', false));

  // Perform a real diff.
  // Switch off the timeout.
  dmp.Diff_Timeout = 0;
  dmp.Diff_DualThreshold = 32;
  // Simple cases.
  assert.deepEqual([[DIFF_DELETE, 'a'], [DIFF_INSERT, 'b']], dmp.diff_main('a', 'b', false));

  assert.deepEqual([[DIFF_DELETE, 'Apple'], [DIFF_INSERT, 'Banana'], [DIFF_EQUAL, 's are a'], [DIFF_INSERT, 'lso'], [DIFF_EQUAL, ' fruit.']], dmp.diff_main('Apples are a fruit.', 'Bananas are also fruit.', false));

  assert.deepEqual([[DIFF_DELETE, 'a'], [DIFF_INSERT, '\u0680'], [DIFF_EQUAL, 'x'], [DIFF_DELETE, '\t'], [DIFF_INSERT, '\0']], dmp.diff_main('ax\t', '\u0680x\0', false));

  // Overlaps.
  assert.deepEqual([[DIFF_DELETE, '1'], [DIFF_EQUAL, 'a'], [DIFF_DELETE, 'y'], [DIFF_EQUAL, 'b'], [DIFF_DELETE, '2'], [DIFF_INSERT, 'xab']], dmp.diff_main('1ayb2', 'abxab', false));

  assert.deepEqual([[DIFF_INSERT, 'xaxcx'], [DIFF_EQUAL, 'abc'], [DIFF_DELETE, 'y']], dmp.diff_main('abcy', 'xaxcxabc', false));

  // Sub-optimal double-ended diff.
  dmp.Diff_DualThreshold = 2;
  assert.deepEqual([[DIFF_INSERT, 'x'], [DIFF_EQUAL, 'a'], [DIFF_DELETE, 'b'], [DIFF_INSERT, 'x'], [DIFF_EQUAL, 'c'], [DIFF_DELETE, 'y'], [DIFF_INSERT, 'xabc']], dmp.diff_main('abcy', 'xaxcxabc', false));
  dmp.Diff_DualThreshold = 32;

  // Timeout.
  dmp.Diff_Timeout = 0.001;  // 1ms
  var a = '`Twas brillig, and the slithy toves\nDid gyre and gimble in the wabe:\nAll mimsy were the borogoves,\nAnd the mome raths outgrabe.\n';
  var b = 'I am the very model of a modern major general,\nI\'ve information vegetable, animal, and mineral,\nI know the kings of England, and I quote the fights historical,\nFrom Marathon to Waterloo, in order categorical.\n';
  // Increase the text lengths by 1024 times to ensure a timeout.
  for (var x = 0; x < 10; x++) {
    a = a + a;
    b = b + b;
  }
  assert.equal(null, dmp.diff_map(a, b));
  dmp.Diff_Timeout = 0;

  // Test the linemode speedup.
  // Must be long to pass the 200 char cutoff.
  a = '1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n';
  b = 'abcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\nabcdefghij\n';
  assert.deepEqual(dmp.diff_main(a, b, false), dmp.diff_main(a, b, true));

  a = '1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n1234567890\n';
  b = 'abcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n1234567890\n1234567890\n1234567890\nabcdefghij\n';
  var texts_linemode = diff_rebuildtexts(dmp.diff_main(a, b, true));
  var texts_textmode = diff_rebuildtexts(dmp.diff_main(a, b, false));
  assert.deepEqual(texts_textmode, texts_linemode);

  // Test null inputs.
  try {
    dmp.diff_main(null, null);
    assert.equal(Error, null);
  } catch (e) {
    // Exception expected.
  }
}


// MATCH TEST FUNCTIONS


function testMatchAlphabet() {
  // Initialise the bitmasks for Bitap.
  // Unique.
  assert.deepEqual({'a':4, 'b':2, 'c':1}, dmp.match_alphabet('abc'));

  // Duplicates.
  assert.deepEqual({'a':37, 'b':18, 'c':8}, dmp.match_alphabet('abcaba'));
}

function testMatchBitap() {
  // Bitap algorithm.
  dmp.Match_Distance = 100;
  dmp.Match_Threshold = 0.5;
  // Exact matches.
  assert.equal(5, dmp.match_bitap('abcdefghijk', 'fgh', 5));

  assert.equal(5, dmp.match_bitap('abcdefghijk', 'fgh', 0));

  // Fuzzy matches.
  assert.equal(4, dmp.match_bitap('abcdefghijk', 'efxhi', 0));

  assert.equal(2, dmp.match_bitap('abcdefghijk', 'cdefxyhijk', 5));

  assert.equal(-1, dmp.match_bitap('abcdefghijk', 'bxy', 1));

  // Overflow.
  assert.equal(2, dmp.match_bitap('123456789xx0', '3456789x0', 2));

  // Threshold test.
  dmp.Match_Threshold = 0.4;
  assert.equal(4, dmp.match_bitap('abcdefghijk', 'efxyhi', 1));

  dmp.Match_Threshold = 0.3;
  assert.equal(-1, dmp.match_bitap('abcdefghijk', 'efxyhi', 1));

  dmp.Match_Threshold = 0.0;
  assert.equal(1, dmp.match_bitap('abcdefghijk', 'bcdef', 1));
  dmp.Match_Threshold = 0.5;

  // Multiple select.
  assert.equal(0, dmp.match_bitap('abcdexyzabcde', 'abccde', 3));

  assert.equal(8, dmp.match_bitap('abcdexyzabcde', 'abccde', 5));

  // Distance test.
  dmp.Match_Distance = 10;  // Strict location.
  assert.equal(-1, dmp.match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24));

  assert.equal(0, dmp.match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdxxefg', 1));

  dmp.Match_Distance = 1000;  // Loose location.
  assert.equal(0, dmp.match_bitap('abcdefghijklmnopqrstuvwxyz', 'abcdefg', 24));
}

function testMatchMain() {
  // Full match.
  // Shortcut matches.
  assert.equal(0, dmp.match_main('abcdef', 'abcdef', 1000));

  assert.equal(-1, dmp.match_main('', 'abcdef', 1));

  assert.equal(3, dmp.match_main('abcdef', '', 3));

  assert.equal(3, dmp.match_main('abcdef', 'de', 3));

  // Beyond end match.
  assert.equal(3, dmp.match_main("abcdef", "defy", 4));

  // Oversized pattern.
  assert.equal(0, dmp.match_main("abcdef", "abcdefy", 0));

  // Complex match.
  assert.equal(4, dmp.match_main('I am the very model of a modern major general.', ' that berry ', 5));

  // Test null inputs.
  try {
    dmp.match_main(null, null, 0);
    assert.equal(Error, null);
  } catch (e) {
    // Exception expected.
  }
}


// PATCH TEST FUNCTIONS


function testPatchObj() {
  // Patch Object.
  var p = new patch_obj();
  p.start1 = 20;
  p.start2 = 21;
  p.length1 = 18;
  p.length2 = 17;
  p.diffs = [[DIFF_EQUAL, 'jump'], [DIFF_DELETE, 's'], [DIFF_INSERT, 'ed'], [DIFF_EQUAL, ' over '], [DIFF_DELETE, 'the'], [DIFF_INSERT, 'a'], [DIFF_EQUAL, '\nlaz']];
  var strp = p.toString();
  assert.equal('@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n', strp);
}

function testPatchFromText() {
  assert.deepEqual([], dmp.patch_fromText(strp));

  var strp = '@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n %0Alaz\n';
  assert.equal(strp, dmp.patch_fromText(strp)[0].toString());

  assert.equal('@@ -1 +1 @@\n-a\n+b\n', dmp.patch_fromText('@@ -1 +1 @@\n-a\n+b\n')[0].toString());

  assert.equal('@@ -1,3 +0,0 @@\n-abc\n', dmp.patch_fromText('@@ -1,3 +0,0 @@\n-abc\n')[0].toString());

  assert.equal('@@ -0,0 +1,3 @@\n+abc\n', dmp.patch_fromText('@@ -0,0 +1,3 @@\n+abc\n')[0].toString());

  // Generates error.
  try {
    dmp.patch_fromText('Bad\nPatch\n');
    assert.equal(Error, null);
  } catch (e) {
    // Exception expected.
  }
}

function testPatchToText() {
  var strp = '@@ -21,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n';
  var p = dmp.patch_fromText(strp);
  assert.equal(strp, dmp.patch_toText(p));

  strp = '@@ -1,9 +1,9 @@\n-f\n+F\n oo+fooba\n@@ -7,9 +7,9 @@\n obar\n-,\n+.\n  tes\n';
  p = dmp.patch_fromText(strp);
  assert.equal(strp, dmp.patch_toText(p));
}

function testPatchAddContext() {
  dmp.Patch_Margin = 4;
  var p = dmp.patch_fromText('@@ -21,4 +21,10 @@\n-jump\n+somersault\n')[0];
  dmp.patch_addContext(p, 'The quick brown fox jumps over the lazy dog.');
  assert.equal('@@ -17,12 +17,18 @@\n fox \n-jump\n+somersault\n s ov\n', p.toString());

  // Same, but not enough trailing context.
  p = dmp.patch_fromText('@@ -21,4 +21,10 @@\n-jump\n+somersault\n')[0];
  dmp.patch_addContext(p, 'The quick brown fox jumps.');
  assert.equal('@@ -17,10 +17,16 @@\n fox \n-jump\n+somersault\n s.\n', p.toString());

  // Same, but not enough leading context.
  p = dmp.patch_fromText('@@ -3 +3,2 @@\n-e\n+at\n')[0];
  dmp.patch_addContext(p, 'The quick brown fox jumps.');
  assert.equal('@@ -1,7 +1,8 @@\n Th\n-e\n+at\n  qui\n', p.toString());

  // Same, but with ambiguity.
  p = dmp.patch_fromText('@@ -3 +3,2 @@\n-e\n+at\n')[0];
  dmp.patch_addContext(p, 'The quick brown fox jumps.  The quick brown fox crashes.');
  assert.equal('@@ -1,27 +1,28 @@\n Th\n-e\n+at\n  quick brown fox jumps. \n', p.toString());
}

function testPatchMake() {
  var text1 = 'The quick brown fox jumps over the lazy dog.';
  var text2 = 'That quick brown fox jumped over a lazy dog.';
  // Text2+Text1 inputs.
  var expectedPatch = '@@ -1,8 +1,7 @@\n Th\n-at\n+e\n  qui\n@@ -21,17 +21,18 @@\n jump\n-ed\n+s\n  over \n-a\n+the\n  laz\n';
  // The second patch must be "-21,17 +21,18", not "-22,17 +21,18" due to rolling context.
  var patches = dmp.patch_make(text2, text1);
  assert.equal(expectedPatch, dmp.patch_toText(patches));

  // Text1+Text2 inputs.
  expectedPatch = '@@ -1,11 +1,12 @@\n Th\n-e\n+at\n  quick b\n@@ -22,18 +22,17 @@\n jump\n-s\n+ed\n  over \n-the\n+a\n  laz\n';
  patches = dmp.patch_make(text1, text2);
  assert.equal(expectedPatch, dmp.patch_toText(patches));

  // Diff input.
  var diffs = dmp.diff_main(text1, text2, false);
  patches = dmp.patch_make(diffs);
  assert.equal(expectedPatch, dmp.patch_toText(patches));

  // Text1+Diff inputs.
  patches = dmp.patch_make(text1, diffs);
  assert.equal(expectedPatch, dmp.patch_toText(patches));

  // Text1+Text2+Diff inputs (deprecated).
  patches = dmp.patch_make(text1, text2, diffs);
  assert.equal(expectedPatch, dmp.patch_toText(patches));

  // Character encoding.
  patches = dmp.patch_make('`1234567890-=[]\\;\',./', '~!@#$%^&*()_+{}|:"<>?');
  assert.equal('@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;\',./\n+~!@#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n', dmp.patch_toText(patches));

  // Character decoding.
  diffs = [[DIFF_DELETE, '`1234567890-=[]\\;\',./'], [DIFF_INSERT, '~!@#$%^&*()_+{}|:"<>?']];
  assert.deepEqual(diffs, dmp.patch_fromText('@@ -1,21 +1,21 @@\n-%601234567890-=%5B%5D%5C;\',./\n+~!@#$%25%5E&*()_+%7B%7D%7C:%22%3C%3E?\n')[0].diffs);

  // Long string with repeats.
  text1 = '';
  for (var x = 0; x < 100; x++) {
    text1 += 'abcdef';
  }
  text2 = text1 + '123';
  expectedPatch = '@@ -573,28 +573,31 @@\n cdefabcdefabcdefabcdefabcdef\n+123\n';
  patches = dmp.patch_make(text1, text2);
  assert.equal(expectedPatch, dmp.patch_toText(patches));

  // Test null inputs.
  try {
    dmp.patch_make(null);
    assert.equal(Error, null);
  } catch (e) {
    // Exception expected.
  }
}

function testPatchSplitMax() {
  // Assumes that dmp.Match_MaxBits is 32.
  var patches = dmp.patch_make('abcdefghijklmnopqrstuvwxyz01234567890', 'XabXcdXefXghXijXklXmnXopXqrXstXuvXwxXyzX01X23X45X67X89X0');
  dmp.patch_splitMax(patches);
  assert.equal('@@ -1,32 +1,46 @@\n+X\n ab\n+X\n cd\n+X\n ef\n+X\n gh\n+X\n ij\n+X\n kl\n+X\n mn\n+X\n op\n+X\n qr\n+X\n st\n+X\n uv\n+X\n wx\n+X\n yz\n+X\n 012345\n@@ -25,13 +39,18 @@\n zX01\n+X\n 23\n+X\n 45\n+X\n 67\n+X\n 89\n+X\n 0\n', dmp.patch_toText(patches));

  patches = dmp.patch_make('abcdef1234567890123456789012345678901234567890123456789012345678901234567890uvwxyz', 'abcdefuvwxyz');
  var oldToText = dmp.patch_toText(patches);
  dmp.patch_splitMax(patches);
  assert.equal(oldToText, dmp.patch_toText(patches));

  patches = dmp.patch_make('1234567890123456789012345678901234567890123456789012345678901234567890', 'abc');
  dmp.patch_splitMax(patches);
  assert.equal('@@ -1,32 +1,4 @@\n-1234567890123456789012345678\n 9012\n@@ -29,32 +1,4 @@\n-9012345678901234567890123456\n 7890\n@@ -57,14 +1,3 @@\n-78901234567890\n+abc\n', dmp.patch_toText(patches));

  patches = dmp.patch_make('abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1 abcdefghij , h : 0 , t : 1', 'abcdefghij , h : 1 , t : 1 abcdefghij , h : 1 , t : 1 abcdefghij , h : 0 , t : 1');
  dmp.patch_splitMax(patches);
  assert.equal('@@ -2,32 +2,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n@@ -29,32 +29,32 @@\n bcdefghij , h : \n-0\n+1\n  , t : 1 abcdef\n', dmp.patch_toText(patches));
}

function testPatchAddPadding() {
  // Both edges full.
  var patches = dmp.patch_make('', 'test');
  assert.equal('@@ -0,0 +1,4 @@\n+test\n', dmp.patch_toText(patches));
  dmp.patch_addPadding(patches);
  assert.equal('@@ -1,8 +1,12 @@\n %01%02%03%04\n+test\n %01%02%03%04\n', dmp.patch_toText(patches));

  // Both edges partial.
  patches = dmp.patch_make('XY', 'XtestY');
  assert.equal('@@ -1,2 +1,6 @@\n X\n+test\n Y\n', dmp.patch_toText(patches));
  dmp.patch_addPadding(patches);
  assert.equal('@@ -2,8 +2,12 @@\n %02%03%04X\n+test\n Y%01%02%03\n', dmp.patch_toText(patches));

  // Both edges none.
  patches = dmp.patch_make('XXXXYYYY', 'XXXXtestYYYY');
  assert.equal('@@ -1,8 +1,12 @@\n XXXX\n+test\n YYYY\n', dmp.patch_toText(patches));
  dmp.patch_addPadding(patches);
  assert.equal('@@ -5,8 +5,12 @@\n XXXX\n+test\n YYYY\n', dmp.patch_toText(patches));
}

function testPatchApply() {
  dmp.Match_Distance = 1000;
  dmp.Match_Threshold = 0.5;
  dmp.Patch_DeleteThreshold = 0.5;

  // Exact match.
  var patches = dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'That quick brown fox jumped over a lazy dog.');
  var results = dmp.patch_apply(patches, 'The quick brown fox jumps over the lazy dog.');
  assert.deepEqual(['That quick brown fox jumped over a lazy dog.', [true, true]], results);

  // Partial match.
  results = dmp.patch_apply(patches, 'The quick red rabbit jumps over the tired tiger.');
  assert.deepEqual(['That quick red rabbit jumped over a tired tiger.', [true, true]], results);

  // Failed match.
  results = dmp.patch_apply(patches, 'I am the very model of a modern major general.');
  assert.deepEqual(['I am the very model of a modern major general.', [false, false]], results);

  // Big delete, small change.
  patches = dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  results = dmp.patch_apply(patches, 'x123456789012345678901234567890-----++++++++++-----123456789012345678901234567890y');
  assert.deepEqual(['xabcy', [true, true]], results);

  // Big delete, big change 1.
  patches = dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  results = dmp.patch_apply(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y');
  assert.deepEqual(['xabc12345678901234567890---------------++++++++++---------------12345678901234567890y', [false, true]], results);

  // Big delete, big change 2.
  dmp.Patch_DeleteThreshold = 0.6;
  patches = dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  results = dmp.patch_apply(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y');
  assert.deepEqual(['xabcy', [true, true]], results);
  dmp.Patch_DeleteThreshold = 0.5;

  // Compensate for failed patch.
  dmp.Match_Threshold = 0.0;
  dmp.Match_Distance = 0;
  patches = dmp.patch_make('abcdefghijklmnopqrstuvwxyz--------------------1234567890', 'abcXXXXXXXXXXdefghijklmnopqrstuvwxyz--------------------1234567YYYYYYYYYY890');
  results = dmp.patch_apply(patches, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567890');
  assert.deepEqual(['ABCDEFGHIJKLMNOPQRSTUVWXYZ--------------------1234567YYYYYYYYYY890', [false, true]], results);
  dmp.Match_Threshold = 0.5;
  dmp.Match_Distance = 1000;

  // No side effects.
  patches = dmp.patch_make('', 'test');
  var patchstr = dmp.patch_toText(patches);
  dmp.patch_apply(patches, '');
  assert.equal(patchstr, dmp.patch_toText(patches));

  // No side effects with major delete.
  patches = dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'Woof');
  patchstr = dmp.patch_toText(patches);
  dmp.patch_apply(patches, 'The quick brown fox jumps over the lazy dog.');
  assert.equal(patchstr, dmp.patch_toText(patches));

  // Edge exact match.
  patches = dmp.patch_make('', 'test');
  results = dmp.patch_apply(patches, '');
  assert.deepEqual(['test', [true]], results);

  // Near edge exact match.
  patches = dmp.patch_make('XY', 'XtestY');
  results = dmp.patch_apply(patches, 'XY');
  assert.deepEqual(['XtestY', [true]], results);

  // Edge partial match.
  patches = dmp.patch_make('y', 'y123');
  results = dmp.patch_apply(patches, 'x');
  assert.deepEqual(['x123', [true]], results);
}

//from the original html file
  function runTests() {
    var tests = ['testDiffCommonPrefix', 'testDiffCommonSuffix', 'testDiffHalfMatch',
        'testDiffLinesToChars', 'testDiffCharsToLines', 'testDiffCleanupMerge',
        'testDiffCleanupSemanticLossless', 'testDiffCleanupSemantic',
        'testDiffCleanupEfficiency', 'testDiffPrettyHtml', 'testDiffText',
        'testDiffDelta', 'testDiffXIndex', 'testDiffLevenshtein', 'testDiffPath',
        'testDiffMain',

        'testMatchAlphabet', 'testMatchBitap', 'testMatchMain',

        'testPatchObj', 'testPatchFromText', 'testPatchToText',
        'testPatchAddContext', 'testPatchMake', 'testPatchSplitMax',
        'testPatchAddPadding', 'testPatchApply'];
    for (var x = 0; x < tests.length; x++) {
      sys.puts("Running test: "+tests[x]);
      eval(tests[x] + '()');
    }
  }

  runTests();
