/**
 * Test Harness for MobWrite Client
 *
 * Copyright (C) November 2007 Google Inc.
 * http://code.google.com/p/google-mobwrite/
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


// If expected and actual are the equivalent, pass the test.
function assertEquivalent(msg, expected, actual) {
  if (typeof actual == 'undefined') {
    // msg is optional.
    actual = expected;
    expected = msg;
    msg = 'Expected: \'' + expected + '\' Actual: \'' + actual + '\'';
  }
  if (_equivalent(expected, actual)) {
    assertEquals(msg, String.toString(expected), String.toString(actual));
  } else {
    assertEquals(msg, expected, actual);
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


// CORE TEST FUNCTIONS


function testUniqueId() {
  // Test length
  assertEquals(8, mobwrite.uniqueId().length);
  // Two IDs should not be the same.
  // There's a 1 in 4 trillion chance this test could fail normally.
  assertEquals(false, mobwrite.uniqueId() == mobwrite.uniqueId());
}


function testComputeSyncInterval() {
  // Check 10% growth when no change.
  mobwrite.serverChange_ = false;
  mobwrite.clientChange_ = false;
  mobwrite.syncInterval = 185;
  mobwrite.minSyncInterval = 100;
  mobwrite.maxSyncInterval = 200;
  mobwrite.computeSyncInterval_();
  assertEquals(195, mobwrite.syncInterval);

  // Check max cap.
  mobwrite.computeSyncInterval_();
  assertEquals(200, mobwrite.syncInterval);

  // Check 20% drop when server changes.
  mobwrite.serverChange_ = true;
  mobwrite.clientChange_ = false;
  mobwrite.syncInterval = 175;
  mobwrite.computeSyncInterval_();
  assertEquals(155, mobwrite.syncInterval);

  // Check 40% drop when client changes.
  mobwrite.serverChange_ = false;
  mobwrite.clientChange_ = true;
  mobwrite.syncInterval = 175;
  mobwrite.computeSyncInterval_();
  assertEquals(135, mobwrite.syncInterval);

  // Check 60% drop when both server and client changes.
  mobwrite.serverChange_ = true;
  mobwrite.clientChange_ = true;
  mobwrite.syncInterval = 175;
  mobwrite.computeSyncInterval_();
  assertEquals(115, mobwrite.syncInterval);

  // Check min cap.
  mobwrite.computeSyncInterval_();
  assertEquals(100, mobwrite.syncInterval);
}


function testSplitBlocks() {
  // Temporarily replace uniqueId with something more deterministic.
  var orig_uniqueId = mobwrite.uniqueId;
  mobwrite.uniqueId = function() { return 'abcdefgh'; };

  mobwrite.syncGateway = 'http://example.com/q.py'; // 23 chars
  var text = 'The quick brown fox jumps over the lazy dog?';
  mobwrite.get_maxchars = 72;
  var blocks = mobwrite.splitBlocks_(text);
  assertEquals('http://example.com/q.py?p=The+quick+brown+fox+jumps+over+the+lazy+dog%3F', blocks[0]);

  mobwrite.get_maxchars = 71;
  blocks = mobwrite.splitBlocks_(text);
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+4+1+The%2520quick%2520brow%0A%0A', blocks[0]);
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+4+2+n%2520fox%2520jumps%25%0A%0A', blocks[1]);
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+4+3+20over%2520the%2520laz%0A%0A', blocks[2]);
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+4+4+y%2520dog%253F%0A%0A', blocks[3]);

  mobwrite.get_maxchars = 69;
  blocks = mobwrite.splitBlocks_(text);
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+5+1+The%2520quick%2520br%0A%0A', blocks[0]);
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+5+2+own%2520fox%2520jump%0A%0A', blocks[1]);
  // Note that this block is shorter to avoid splitting the '%25'.
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+5+3+s%2520over%2520the%0A%0A', blocks[2]);
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+5+4+%2520lazy%2520dog%25%0A%0A', blocks[3]);
  // Note that this block is unexpectedly added due rollover from the unsplit '%25'.
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+5+5+3F%0A%0A', blocks[4]);

  // Ensure that an even ending doesn't generate a blank extra block.
  mobwrite.get_maxchars = 54;
  blocks = mobwrite.splitBlocks_('123451234512345123451234512345');
  assertEquals('http://example.com/q.py?p=b%3Aabcdefgh+6+6+12345%0A%0A', blocks[5]);

  // Restore uniqueId
  mobwrite.uniqueId = orig_uniqueId;
}


// FORM TEST FUNCTIONS


function testValidNode() {
  var div = document.createElement('div');
  var textarea = document.createElement('textarea');
  assertEquals(false, mobwrite.validNode_(textarea));
  div.appendChild(textarea);
  assertEquals(false, mobwrite.validNode_(textarea));
  document.body.appendChild(div);
  assertEquals(true, mobwrite.validNode_(textarea));
  document.body.removeChild(div);
  assertEquals(false, mobwrite.validNode_(textarea));
}


function testShareHandler() {
  // Prevent the MobWrite task from starting.
  var oldPid = mobwrite.syncRunPid_
  mobwrite.syncRunPid_ = 1;

  // Setup a textarea.
  var textarea = document.createElement('textarea');
  textarea.id = 'test_textarea';
  textarea.value = 'Hello World!';
  document.body.appendChild(textarea);
  // Textarea is not currently shared.
  assertEquals(false, textarea.id in mobwrite.shared);

  // Share the textarea.
  mobwrite.share(textarea);
  assertEquals(true, textarea.id in mobwrite.shared);
  var shareobj = mobwrite.shared[textarea.id];

  // Share the textarea again and ensure it is not overwritten.
  mobwrite.share(textarea);
  assertEquals(true, shareobj === mobwrite.shared[textarea.id]);

  // Read from textarea and ensure its continued existance.
  assertEquals(textarea.value, shareobj.getClientText());
  assertEquals(true, textarea.id in mobwrite.shared);

  // Unshare the textarea.
  mobwrite.unshare(textarea);
  assertEquals(false, textarea.id in mobwrite.shared);

  // Unshare the textarea again for fun.
  mobwrite.unshare(textarea);
  assertEquals(false, textarea.id in mobwrite.shared);

  // Share the textarea again.
  mobwrite.share(textarea);
  assertEquals(true, textarea.id in mobwrite.shared);
  shareobj = mobwrite.shared[textarea.id];

  // Remove the textarea from the DOM and verify that it gets unshared.
  document.body.removeChild(textarea);
  assertEquals(textarea.value, shareobj.getClientText());
  assertEquals(false, textarea.id in mobwrite.shared);

  // Restore MobWrite's task Pid.
  mobwrite.syncRunPid_ = oldPid;
}


// TEXTAREA TEST FUNCTIONS


function testNormalizeLinebreaks() {
  // Single
  assertEquals('\n', mobwrite.shareTextareaObj.normalizeLinebreaks_('\n'));
  assertEquals('\n', mobwrite.shareTextareaObj.normalizeLinebreaks_('\r'));
  assertEquals('\n', mobwrite.shareTextareaObj.normalizeLinebreaks_('\r\n'));
  // Double
  assertEquals('\n\n', mobwrite.shareTextareaObj.normalizeLinebreaks_('\n\n'));
  assertEquals('\n\n', mobwrite.shareTextareaObj.normalizeLinebreaks_('\r\r'));
  assertEquals('\n\n', mobwrite.shareTextareaObj.normalizeLinebreaks_('\r\n\r\n'));
  // Mixed
  assertEquals('_\n_\n_\n_ _\n\n_\n\n_\n\n_',
      mobwrite.shareTextareaObj.normalizeLinebreaks_('_\n_\r_\r\n_ _\n\n_\r\r_\r\n\r\n_'));
}


function testCursor() {
  // Create a textarea.
  var textarea = document.createElement('textarea');
  textarea.id = 'test_textarea';
  document.body.appendChild(textarea);
  var text = 'The quick brown fox jumped over the lazy dog.\n' +
      'She sells sea shells by the sea shore.';
  textarea.value = text;
  textarea.focus();
  // IE and Opera instantly convert \n into \r\n.  Gecko and Webkit don't.
  text = textarea.value;
  var linebreak = '\n';
  if (textarea.value.indexOf('\r\n') != -1) {
    linebreak = '\r\n';
  }
  var share = new mobwrite.shareTextareaObj(textarea);

  // Fabricate a collapsed cursor right before 'shore'.
  var cursor0 = {};
  cursor0.startPrefix = 'ells by the sea ';
  cursor0.startSuffix = 'shore.';
  cursor0.startOffset = 77 + linebreak.length;
  cursor0.collapsed = true;
  share.restoreCursor_(cursor0);

  // Check the captured cursor is the same as the fabricated cursor.
  var cursor1 = share.captureCursor_();
  assertEquals(cursor0.startPrefix, cursor1.startPrefix);
  assertEquals(cursor0.startSuffix, cursor1.startSuffix);
  assertEquals(cursor0.startOffset, cursor1.startOffset);
  assertEquals(cursor0.collapsed, cursor1.collapsed);

  // Fabricate a selection running from 'lazy' to 'sells' inclusive.
  cursor0 = {};
  cursor0.startPrefix = 'jumped over the ';
  cursor0.startSuffix = 'lazy dog.' + linebreak + 'She se';
  cursor0.startSuffix = cursor0.startSuffix.substring(0, 16);
  cursor0.startOffset = 36;
  cursor0.endPrefix = 'y dog.' + linebreak + 'She sells';
  cursor0.endPrefix = cursor0.endPrefix
      .substring(cursor0.endPrefix.length - 16);
  cursor0.endSuffix = ' sea shells by t';
  cursor0.endOffset = 54 + linebreak.length;
  cursor0.collapsed = false;
  share.restoreCursor_(cursor0);

  // Check the captured cursor is the same as the fabricated cursor.
  cursor1 = share.captureCursor_();
  assertEquals(cursor0.startPrefix, cursor1.startPrefix);
  assertEquals(cursor0.startSuffix, cursor1.startSuffix);
  assertEquals(cursor0.startOffset, cursor1.startOffset);
  assertEquals(cursor0.endPrefix, cursor1.endPrefix);
  assertEquals(cursor0.endSuffix, cursor1.endSuffix);
  assertEquals(cursor0.endOffset, cursor1.endOffset);
  assertEquals(cursor0.collapsed, cursor1.collapsed);

  // Tweak locations and verify fuzzy match.
  cursor1.startPrefix = 'jumped under the ';
  cursor1.startSuffix = 'crazy cats.\tShe';
  cursor1.endOffset = 60;
  share.restoreCursor_(cursor1);
  var cursor2 = share.captureCursor_();
  assertEquals(cursor0.startPrefix, cursor2.startPrefix);
  assertEquals(cursor0.startSuffix, cursor2.startSuffix);
  assertEquals(cursor0.startOffset, cursor2.startOffset);
  assertEquals(cursor0.endPrefix, cursor2.endPrefix);
  assertEquals(cursor0.endSuffix, cursor2.endSuffix);
  assertEquals(cursor0.endOffset, cursor2.endOffset);
  assertEquals(cursor0.collapsed, cursor2.collapsed);

  // Tear down the text area.
  document.body.removeChild(textarea);
}


function testPatchApply() {
  // Create a shareTextareaObj.
  var textarea = document.createElement('textarea');
  textarea.id = 'test_textarea';
  var share = new mobwrite.shareTextareaObj(textarea);
  share.dmp.Match_Distance = 1000;
  share.dmp.Match_Threshold = 0.5;
  share.dmp.Patch_DeleteThreshold = 0.5;

  // Exact match.
  var patches = share.dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'That quick brown fox jumped over a lazy dog.');
  var offsets = [0, 2, 4, 23, 26, 30, 35, 100];
  var result = share.patch_apply_(patches, 'The quick brown fox jumps over the lazy dog.', offsets);
  assertEquals('That quick brown fox jumped over a lazy dog.', result);
  assertEquivalent([0, 2, 5, 24, 28, 32, 35, 100], offsets);

  // Partial match.
  result = share.patch_apply_(patches, 'The quick red rabbit jumps over the tired tiger.', offsets);
  assertEquals('That quick red rabbit jumped over a tired tiger.', result);

  // Failed match.
  result = share.patch_apply_(patches, 'I am the very model of a modern major general.', offsets);
  assertEquals('I am the very model of a modern major general.', result);

  // Big delete, small change.
  patches = share.dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  result = share.patch_apply_(patches, 'x123456789012345678901234567890-----++++++++++-----123456789012345678901234567890y', offsets);
  assertEquivalent('xabcy', result);

  // Big delete, big change 1.
  patches = share.dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  result = share.patch_apply_(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y', offsets);
  assertEquivalent('xabc12345678901234567890---------------++++++++++---------------12345678901234567890y', result);

  // Big delete, big change 2.
  share.dmp.Patch_DeleteThreshold = 0.6;
  patches = share.dmp.patch_make('x1234567890123456789012345678901234567890123456789012345678901234567890y', 'xabcy');
  result = share.patch_apply_(patches, 'x12345678901234567890---------------++++++++++---------------12345678901234567890y', offsets);
  assertEquivalent('xabcy', result);
  share.dmp.Patch_DeleteThreshold = 0.5;

  // No side effects.
  patches = share.dmp.patch_make('', 'test');
  var patchstr = share.dmp.patch_toText(patches);
  share.patch_apply_(patches, '', offsets);
  assertEquals(patchstr, share.dmp.patch_toText(patches));

  // No side effects with major delete.
  offsets = [0, 43, 45, 100];
  patches = share.dmp.patch_make('The quick brown fox jumps over the lazy dog.', 'Woof');
  patchstr = share.dmp.patch_toText(patches);
  share.patch_apply_(patches, 'The quick brown fox jumps over the lazy dog.', offsets);
  assertEquals(patchstr, share.dmp.patch_toText(patches));
  assertEquivalent([0, 0, 5, 60], offsets);

  // Edge exact match.
  patches = share.dmp.patch_make('', 'test');
  result = share.patch_apply_(patches, '', offsets);
  assertEquals('test', result);

  // Near edge exact match.
  patches = share.dmp.patch_make('XY', 'XtestY');
  result = share.patch_apply_(patches, 'XY', offsets);
  assertEquals('XtestY', result);

  // Edge partial match.
  patches = share.dmp.patch_make('y', 'y123');
  result = share.patch_apply_(patches, 'x', offsets);
  assertEquals('x123', result);
}


function testMergeType() {
  // Create a text input.
  var input = document.createElement('input');
  input.id = 'test_input';
  document.body.appendChild(input);
  var share = new mobwrite.shareTextareaObj(input);

  // Check that text will merge.
  input.value = '12Hello34';
  share.getClientText();
  assertEquals(true, share.mergeChanges);

  // Check that numbers will not merge.
  input.value = ' 12,345.67 ';
  share.getClientText();
  assertEquals(false, share.mergeChanges);

  // Tear down the text input.
  document.body.removeChild(input);
}

