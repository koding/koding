/**
 * MobWrite - Real-time Synchronization and Collaboration Service
 *
 * Copyright 2008 Google Inc.
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

/**
 * @fileoverview This client-side code interfaces with form elements.
 * @author fraser@google.com (Neil Fraser)
 */

/**
 * Checks to see if the provided node is still part of the DOM.
 * @param {Node} node DOM node to verify.
 * @return {boolean} Is this node part of a DOM?
 * @private
 */
mobwrite.validNode_ = function(node) {
  while (node.parentNode) {
    node = node.parentNode;
  }
  // The topmost node should be type 9, a document.
  return node.nodeType == 9;
};


// FORM


/**
 * Handler to accept forms as elements that can be shared.
 * Share each of the form's elements.
 * @param {Object|string} form Form or ID of form to share
 * @return {Object?} A sharing object or null.
 */
mobwrite.shareHandlerForm = function(form) {
  if (typeof form == 'string') {
    form = document.getElementById(form) || document.forms[form];
  }
  if (form && 'tagName' in form && form.tagName == 'FORM') {
    for (var x = 0, el; el = form.elements[x]; x++) {
      mobwrite.share(el);
    }
  }
  return null;
};


// Register this shareHandler with MobWrite.
mobwrite.shareHandlers.push(mobwrite.shareHandlerForm);


// HIDDEN


/**
 * Constructor of shared object representing a hidden input.
 * @param {Node} node A hidden element.
 * @constructor
 */
mobwrite.shareHiddenObj = function(node) {
  // Call our prototype's constructor.
  mobwrite.shareObj.apply(this, [node.id]);
  this.element = node;
};


// The hidden input's shared object's parent is a shareObj.
mobwrite.shareHiddenObj.prototype = new mobwrite.shareObj('');


/**
 * Retrieve the user's content.
 * @return {string} Plaintext content.
 */
mobwrite.shareHiddenObj.prototype.getClientText = function() {
  if (!mobwrite.validNode_(this.element)) {
    mobwrite.unshare(this.file);
  }
  // Numeric data should use overwrite mode.
  this.mergeChanges = !this.element.value.match(/^\s*-?[\d.]+\s*$/);
  return this.element.value;
};


/**
 * Set the user's content.
 * @param {string} text New content.
 */
mobwrite.shareHiddenObj.prototype.setClientText = function(text) {
  this.element.value = text;
};


/**
 * Handler to accept hidden fields as elements that can be shared.
 * If the element is a hidden field, create a new sharing object.
 * @param {*} node Object or ID of object to share.
 * @return {Object?} A sharing object or null.
 */
mobwrite.shareHiddenObj.shareHandler = function(node) {
  if (typeof node == 'string') {
    node = document.getElementById(node);
  }
  if (node && 'type' in node && node.type == 'hidden') {
    return new mobwrite.shareHiddenObj(node);
  }
  return null;
};


// Register this shareHandler with MobWrite.
mobwrite.shareHandlers.push(mobwrite.shareHiddenObj.shareHandler);


// CHECKBOX


/**
 * Constructor of shared object representing a checkbox.
 * @param {Node} node A checkbox element.
 * @constructor
 */
mobwrite.shareCheckboxObj = function(node) {
  // Call our prototype's constructor.
  mobwrite.shareObj.apply(this, [node.id]);
  this.element = node;
  this.mergeChanges = false;
};


// The checkbox shared object's parent is a shareObj.
mobwrite.shareCheckboxObj.prototype = new mobwrite.shareObj('');


/**
 * Retrieve the user's check.
 * @return {string} Plaintext content.
 */
mobwrite.shareCheckboxObj.prototype.getClientText = function() {
  if (!mobwrite.validNode_(this.element)) {
    mobwrite.unshare(this.file);
  }
  return this.element.checked ? this.element.value : '';
};


/**
 * Set the user's check.
 * @param {string} text New content.
 */
mobwrite.shareCheckboxObj.prototype.setClientText = function(text) {
  // Safari has a blank value if not set, all other browsers have 'on'.
  var value = this.element.value || 'on';
  this.element.checked = (text == value);
  this.fireChange(this.element);
};


/**
 * Handler to accept checkboxen as elements that can be shared.
 * If the element is a checkbox, create a new sharing object.
 * @param {*} node Object or ID of object to share.
 * @return {Object?} A sharing object or null.
 */
mobwrite.shareCheckboxObj.shareHandler = function(node) {
  if (typeof node == 'string') {
    node = document.getElementById(node);
  }
  if (node && 'type' in node && node.type == 'checkbox') {
    return new mobwrite.shareCheckboxObj(node);
  }
  return null;
};


// Register this shareHandler with MobWrite.
mobwrite.shareHandlers.push(mobwrite.shareCheckboxObj.shareHandler);


// SELECT OPTION


/**
 * Constructor of shared object representing a select box.
 * @param {Node} node A select box element.
 * @constructor
 */
mobwrite.shareSelectObj = function(node) {
  // Call our prototype's constructor.
  mobwrite.shareObj.apply(this, [node.id]);
  this.element = node;
  // If the select box is select-one, use overwrite mode.
  // If it is select-multiple, use text merge mode.
  this.mergeChanges = (node.type == 'select-multiple');
};


// The select box shared object's parent is a shareObj.
mobwrite.shareSelectObj.prototype = new mobwrite.shareObj('');


/**
 * Retrieve the user's selection(s).
 * @return {string} Plaintext content.
 */
mobwrite.shareSelectObj.prototype.getClientText = function() {
  if (!mobwrite.validNode_(this.element)) {
    mobwrite.unshare(this.file);
  }
  var selected = [];
  for (var x = 0, option; option = this.element.options[x]; x++) {
    if (option.selected) {
      selected.push(option.value);
    }
  }
  return selected.join('\0');
};


/**
 * Set the user's selection(s).
 * @param {string} text New content.
 */
mobwrite.shareSelectObj.prototype.setClientText = function(text) {
  text = '\0' + text + '\0';
  for (var x = 0, option; option = this.element.options[x]; x++) {
    option.selected = (text.indexOf('\0' + option.value + '\0') != -1);
  }
  this.fireChange(this.element);
};


/**
 * Handler to accept select boxen as elements that can be shared.
 * If the element is a select box, create a new sharing object.
 * @param {*} node Object or ID of object to share
 * @return {Object?} A sharing object or null.
 */
mobwrite.shareSelectObj.shareHandler = function(node) {
  if (typeof node == 'string') {
    node = document.getElementById(node);
  }
  if (node && 'type' in node && (node.type == 'select-one' || node.type == 'select-multiple')) {
    return new mobwrite.shareSelectObj(node);
  }
  return null;
};


// Register this shareHandler with MobWrite.
mobwrite.shareHandlers.push(mobwrite.shareSelectObj.shareHandler);


// RADIO BUTTON


/**
 * Constructor of shared object representing a radio button.
 * @param {Node} node A radio button element.
 * @constructor
 */
mobwrite.shareRadioObj = function(node) {
  // Call our prototype's constructor.
  mobwrite.shareObj.apply(this, [node.id]);
  this.elements = [node];
  this.form = node.form;
  this.name = node.name;
  this.mergeChanges = false;
};


// The radio button shared object's parent is a shareObj.
mobwrite.shareRadioObj.prototype = new mobwrite.shareObj('');


/**
 * Retrieve the user's check.
 * @return {string} Plaintext content.
 */
mobwrite.shareRadioObj.prototype.getClientText = function() {
  // TODO: Handle cases where the radio buttons are added or removed.
  if (!mobwrite.validNode_(this.elements[0])) {
    mobwrite.unshare(this.file);
  }
  // Group of radio buttons
  for (var x = 0; x < this.elements.length; x++) {
    if (this.elements[x].checked) {
      return this.elements[x].value;
    }
  }
  // Nothing checked.
  return '';
};


/**
 * Set the user's check.
 * @param {string} text New content.
 */
mobwrite.shareRadioObj.prototype.setClientText = function(text) {
  for (var x = 0; x < this.elements.length; x++) {
    this.elements[x].checked = (text == this.elements[x].value);
    this.fireChange(this.elements[x]);
  }
};


/**
 * Handler to accept radio buttons as elements that can be shared.
 * If the element is a radio button, create a new sharing object.
 * @param {*} node Object or ID of object to share.
 * @return {Object?} A sharing object or null.
 */
mobwrite.shareRadioObj.shareHandler = function(node) {
  if (typeof node == 'string') {
    node = document.getElementById(node);
  }
  if (node && 'type' in node && node.type == 'radio') {
    // Check to see if this is another element of an existing radio button group.
    for (var id in mobwrite.shared) {
      if (mobwrite.shared[id].form == node.form && mobwrite.shared[id].name == node.name) {
        mobwrite.shared[id].elements.push(node);
        return null;
      }
    }
    // Create new radio button object.
    return new mobwrite.shareRadioObj(node);
  }
  return null;
};


// Register this shareHandler with MobWrite.
mobwrite.shareHandlers.push(mobwrite.shareRadioObj.shareHandler);


// TEXTAREA, TEXT & PASSWORD INPUTS


/**
 * Constructor of shared object representing a text field.
 * @param {Node} node A textarea, text or password input.
 * @constructor
 */
mobwrite.shareTextareaObj = function(node) {
  // Call our prototype's constructor.
  mobwrite.shareObj.apply(this, [node.id]);
  this.element = node;
  if (node.type == 'password') {
    // Use overwrite mode for password field, users can't see.
    this.mergeChanges = false;
  }
};


// The textarea shared object's parent is a shareObj.
mobwrite.shareTextareaObj.prototype = new mobwrite.shareObj('');


/**
 * Retrieve the user's text.
 * @return {string} Plaintext content.
 */
mobwrite.shareTextareaObj.prototype.getClientText = function() {
  if (!mobwrite.validNode_(this.element)) {
    mobwrite.unshare(this.file);
  }
  var text = mobwrite.shareTextareaObj.normalizeLinebreaks_(this.element.value);
  if (this.element.type == 'text') {
    // Numeric data should use overwrite mode.
    this.mergeChanges = !text.match(/^\s*-?[\d.,]+\s*$/);
  }
  return text;
};


/**
 * Set the user's text.
 * @param {string} text New text
 */
mobwrite.shareTextareaObj.prototype.setClientText = function(text) {
  this.element.value = text;
  this.fireChange(this.element);
};


/**
 * Modify the user's plaintext by applying a series of patches against it.
 * @param {Array.<patch_obj>} patches Array of Patch objects.
 */
mobwrite.shareTextareaObj.prototype.patchClientText = function(patches) {
  // Set some constants which tweak the matching behaviour.
  // Maximum distance to search from expected location.
  this.dmp.Match_Distance = 1000;
  // At what point is no match declared (0.0 = perfection, 1.0 = very loose)
  this.dmp.Match_Threshold = 0.6;

  var oldClientText = this.getClientText();
  var cursor = this.captureCursor_();
  // Pack the cursor offsets into an array to be adjusted.
  // See http://neil.fraser.name/writing/cursor/
  var offsets = [];
  if (cursor) {
    offsets[0] = cursor.startOffset;
    if ('endOffset' in cursor) {
      offsets[1] = cursor.endOffset;
    }
  }
  var newClientText = this.patch_apply_(patches, oldClientText, offsets);
  // Set the new text only if there is a change to be made.
  if (oldClientText != newClientText) {
    this.setClientText(newClientText);
    if (cursor) {
      // Unpack the offset array.
      cursor.startOffset = offsets[0];
      if (offsets.length > 1) {
        cursor.endOffset = offsets[1];
        if (cursor.startOffset >= cursor.endOffset) {
          cursor.collapsed = true;
        }
      }
      this.restoreCursor_(cursor);
    }
  }
};


/**
 * Merge a set of patches onto the text.  Return a patched text.
 * @param {Array.<patch_obj>} patches Array of patch objects.
 * @param {string} text Old text.
 * @param {Array.<number>} offsets Offset indices to adjust.
 * @return {string} New text.
 */
mobwrite.shareTextareaObj.prototype.patch_apply_ =
    function(patches, text, offsets) {
  if (patches.length == 0) {
    return text;
  }

  // Deep copy the patches so that no changes are made to originals.
  patches = this.dmp.patch_deepCopy(patches);
  var nullPadding = this.dmp.patch_addPadding(patches);
  text = nullPadding + text + nullPadding;

  this.dmp.patch_splitMax(patches);
  // delta keeps track of the offset between the expected and actual location
  // of the previous patch.  If there are patches expected at positions 10 and
  // 20, but the first patch was found at 12, delta is 2 and the second patch
  // has an effective expected position of 22.
  var delta = 0;
  for (var x = 0; x < patches.length; x++) {
    var expected_loc = patches[x].start2 + delta;
    var text1 = this.dmp.diff_text1(patches[x].diffs);
    var start_loc;
    var end_loc = -1;
    if (text1.length > this.dmp.Match_MaxBits) {
      // patch_splitMax will only provide an oversized pattern in the case of
      // a monster delete.
      start_loc = this.dmp.match_main(text,
          text1.substring(0, this.dmp.Match_MaxBits), expected_loc);
      if (start_loc != -1) {
        end_loc = this.dmp.match_main(text,
            text1.substring(text1.length - this.dmp.Match_MaxBits),
            expected_loc + text1.length - this.dmp.Match_MaxBits);
        if (end_loc == -1 || start_loc >= end_loc) {
          // Can't find valid trailing context.  Drop this patch.
          start_loc = -1;
        }
      }
    } else {
      start_loc = this.dmp.match_main(text, text1, expected_loc);
    }
    if (start_loc == -1) {
      // No match found.  :(
      if (mobwrite.debug) {
        window.console.warn('Patch failed: ' + patches[x]);
      }
      // Subtract the delta for this failed patch from subsequent patches.
      delta -= patches[x].length2 - patches[x].length1;
    } else {
      // Found a match.  :)
      if (mobwrite.debug) {
        window.console.info('Patch OK.');
      }
      delta = start_loc - expected_loc;
      var text2;
      if (end_loc == -1) {
        text2 = text.substring(start_loc, start_loc + text1.length);
      } else {
        text2 = text.substring(start_loc, end_loc + this.dmp.Match_MaxBits);
      }
      // Run a diff to get a framework of equivalent indices.
      var diffs = this.dmp.diff_main(text1, text2, false);
      if (text1.length > this.dmp.Match_MaxBits &&
          this.dmp.diff_levenshtein(diffs) / text1.length >
          this.dmp.Patch_DeleteThreshold) {
        // The end points match, but the content is unacceptably bad.
        if (mobwrite.debug) {
          window.console.warn('Patch contents mismatch: ' + patches[x]);
        }
      } else {
        var index1 = 0;
        var index2;
        for (var y = 0; y < patches[x].diffs.length; y++) {
          var mod = patches[x].diffs[y];
          if (mod[0] !== DIFF_EQUAL) {
            index2 = this.dmp.diff_xIndex(diffs, index1);
          }
          if (mod[0] === DIFF_INSERT) {  // Insertion
            text = text.substring(0, start_loc + index2) + mod[1] +
                   text.substring(start_loc + index2);
            for (var i = 0; i < offsets.length; i++) {
              if (offsets[i] + nullPadding.length > start_loc + index2) {
                offsets[i] += mod[1].length;
              }
            }
          } else if (mod[0] === DIFF_DELETE) {  // Deletion
            var del_start = start_loc + index2;
            var del_end = start_loc + this.dmp.diff_xIndex(diffs,
                index1 + mod[1].length);
            text = text.substring(0, del_start) + text.substring(del_end);
            for (var i = 0; i < offsets.length; i++) {
              if (offsets[i] + nullPadding.length > del_start) {
                if (offsets[i] + nullPadding.length < del_end) {
                  offsets[i] = del_start - nullPadding.length;
                } else {
                  offsets[i] -= del_end - del_start;
                }
              }
            }
          }
          if (mod[0] !== DIFF_DELETE) {
            index1 += mod[1].length;
          }
        }
      }
    }
  }
  // Strip the padding off.
  text = text.substring(nullPadding.length, text.length - nullPadding.length);
  return text;
};


/**
 * Record information regarding the current cursor.
 * @return {Object?} Context information of the cursor.
 * @private
 */
mobwrite.shareTextareaObj.prototype.captureCursor_ = function() {
  if ('activeElement' in this.element && !this.element.activeElement) {
    // Safari specific code.
    // Restoring a cursor in an unfocused element causes the focus to jump.
    return null;
  }
  var padLength = this.dmp.Match_MaxBits / 2;  // Normally 16.
  var text = this.element.value;
  var cursor = {};
  if ('selectionStart' in this.element) {  // W3
    try {
      var selectionStart = this.element.selectionStart;
      var selectionEnd = this.element.selectionEnd;
    } catch (e) {
      // No cursor; the element may be "display:none".
      return null;
    }
    cursor.startPrefix = text.substring(selectionStart - padLength, selectionStart);
    cursor.startSuffix = text.substring(selectionStart, selectionStart + padLength);
    cursor.startOffset = selectionStart;
    cursor.collapsed = (selectionStart == selectionEnd);
    if (!cursor.collapsed) {
      cursor.endPrefix = text.substring(selectionEnd - padLength, selectionEnd);
      cursor.endSuffix = text.substring(selectionEnd, selectionEnd + padLength);
      cursor.endOffset = selectionEnd;
    }
  } else {  // IE
    // Walk up the tree looking for this textarea's document node.
    var doc = this.element;
    while (doc.parentNode) {
      doc = doc.parentNode;
    }
    if (!doc.selection || !doc.selection.createRange) {
      // Not IE?
      return null;
    }
    var range = doc.selection.createRange();
    if (range.parentElement() != this.element) {
      // Cursor not in this textarea.
      return null;
    }
    var newRange = doc.body.createTextRange();

    cursor.collapsed = (range.text == '');
    newRange.moveToElementText(this.element);
    if (!cursor.collapsed) {
      newRange.setEndPoint('EndToEnd', range);
      cursor.endPrefix = newRange.text;
      cursor.endOffset = cursor.endPrefix.length;
      cursor.endPrefix = cursor.endPrefix.substring(cursor.endPrefix.length - padLength);
    }
    newRange.setEndPoint('EndToStart', range);
    cursor.startPrefix = newRange.text;
    cursor.startOffset = cursor.startPrefix.length;
    cursor.startPrefix = cursor.startPrefix.substring(cursor.startPrefix.length - padLength);

    newRange.moveToElementText(this.element);
    newRange.setEndPoint('StartToStart', range);
    cursor.startSuffix = newRange.text.substring(0, padLength);
    if (!cursor.collapsed) {
      newRange.setEndPoint('StartToEnd', range);
      cursor.endSuffix = newRange.text.substring(0, padLength);
    }
  }

  // Record scrollbar locations
  if ('scrollTop' in this.element) {
    cursor.scrollTop = this.element.scrollTop / this.element.scrollHeight;
    cursor.scrollLeft = this.element.scrollLeft / this.element.scrollWidth;
  }

  // alert(cursor.startPrefix + '|' + cursor.startSuffix + ' ' +
  //     cursor.startOffset + '\n' + cursor.endPrefix + '|' +
  //     cursor.endSuffix + ' ' + cursor.endOffset + '\n' +
  //     cursor.scrollTop + ' x ' + cursor.scrollLeft);
  return cursor;
};


/**
 * Attempt to restore the cursor's location.
 * @param {Object} cursor Context information of the cursor.
 * @private
 */
mobwrite.shareTextareaObj.prototype.restoreCursor_ = function(cursor) {
  // Set some constants which tweak the matching behaviour.
  // Maximum distance to search from expected location.
  this.dmp.Match_Distance = 1000;
  // At what point is no match declared (0.0 = perfection, 1.0 = very loose)
  this.dmp.Match_Threshold = 0.9;

  var padLength = this.dmp.Match_MaxBits / 2;  // Normally 16.
  var newText = this.element.value;

  // Find the start of the selection in the new text.
  var pattern1 = cursor.startPrefix + cursor.startSuffix;
  var pattern2, diff;
  var cursorStartPoint = this.dmp.match_main(newText, pattern1,
      cursor.startOffset - padLength);
  if (cursorStartPoint !== null) {
    pattern2 = newText.substring(cursorStartPoint,
                                 cursorStartPoint + pattern1.length);
    //alert(pattern1 + '\nvs\n' + pattern2);
    // Run a diff to get a framework of equivalent indicies.
    diff = this.dmp.diff_main(pattern1, pattern2, false);
    cursorStartPoint += this.dmp.diff_xIndex(diff, cursor.startPrefix.length);
  }

  var cursorEndPoint = null;
  if (!cursor.collapsed) {
    // Find the end of the selection in the new text.
    pattern1 = cursor.endPrefix + cursor.endSuffix;
    cursorEndPoint = this.dmp.match_main(newText, pattern1,
        cursor.endOffset - padLength);
    if (cursorEndPoint !== null) {
      pattern2 = newText.substring(cursorEndPoint,
                                   cursorEndPoint + pattern1.length);
      //alert(pattern1 + '\nvs\n' + pattern2);
      // Run a diff to get a framework of equivalent indicies.
      diff = this.dmp.diff_main(pattern1, pattern2, false);
      cursorEndPoint += this.dmp.diff_xIndex(diff, cursor.endPrefix.length);
    }
  }

  // Deal with loose ends
  if (cursorStartPoint === null && cursorEndPoint !== null) {
    // Lost the start point of the selection, but we have the end point.
    // Collapse to end point.
    cursorStartPoint = cursorEndPoint;
  } else if (cursorStartPoint === null && cursorEndPoint === null) {
    // Lost both start and end points.
    // Jump to the offset of start.
    cursorStartPoint = cursor.startOffset;
  }
  if (cursorEndPoint === null) {
    // End not known, collapse to start.
    cursorEndPoint = cursorStartPoint;
  }

  // Restore selection.
  if ('selectionStart' in this.element) {  // W3
    this.element.selectionStart = cursorStartPoint;
    this.element.selectionEnd = cursorEndPoint;
  } else {  // IE
    // Walk up the tree looking for this textarea's document node.
    var doc = this.element;
    while (doc.parentNode) {
      doc = doc.parentNode;
    }
    if (!doc.selection || !doc.selection.createRange) {
      // Not IE?
      return;
    }
    // IE's TextRange.move functions treat '\r\n' as one character.
    var snippet = this.element.value.substring(0, cursorStartPoint);
    var ieStartPoint = snippet.replace(/\r\n/g, '\n').length;

    var newRange = doc.body.createTextRange();
    newRange.moveToElementText(this.element);
    newRange.collapse(true);
    newRange.moveStart('character', ieStartPoint);
    if (!cursor.collapsed) {
      snippet = this.element.value.substring(cursorStartPoint, cursorEndPoint);
      var ieMidLength = snippet.replace(/\r\n/g, '\n').length;
      newRange.moveEnd('character', ieMidLength);
    }
    newRange.select();
  }

  // Restore scrollbar locations
  if ('scrollTop' in cursor) {
    this.element.scrollTop = cursor.scrollTop * this.element.scrollHeight;
    this.element.scrollLeft = cursor.scrollLeft * this.element.scrollWidth;
  }
};


/**
 * Ensure that all linebreaks are LF
 * @param {string} text Text with unknown line breaks
 * @return {string} Text with normalized linebreaks
 * @private
 */
mobwrite.shareTextareaObj.normalizeLinebreaks_ = function(text) {
  return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
};


/**
 * Handler to accept text fields as elements that can be shared.
 * If the element is a textarea, text or password input, create a new
 * sharing object.
 * @param {*} node Object or ID of object to share.
 * @return {Object?} A sharing object or null.
 */
mobwrite.shareTextareaObj.shareHandler = function(node) {
  if (typeof node == 'string') {
    node = document.getElementById(node);
  }
  if (node && 'value' in node && 'type' in node && (node.type == 'textarea' ||
      node.type == 'text' || node.type == 'password')) {
    if (mobwrite.UA_webkit) {
      // Safari needs to track which text element has the focus.
      node.addEventListener('focus', function() {this.activeElement = true;},
          false);
      node.addEventListener('blur', function() {this.activeElement = false;},
          false);
      node.activeElement = false;
    }
    return new mobwrite.shareTextareaObj(node);
  }
  return null;
};


// Register this shareHandler with MobWrite.
mobwrite.shareHandlers.push(mobwrite.shareTextareaObj.shareHandler);
