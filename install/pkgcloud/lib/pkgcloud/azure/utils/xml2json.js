/**
 *  (C) Microsoft Open Technologies, Inc.   All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var xml2js = require('xml2js');

exports.xml2JSON = function (xml, callback) {
  // Remove utf-8 BOM if it is at the start of the string
  // utf-8 BOM (EF BB BF) at start of string causes xml2js to blow up
  // azure sometimes includes it in a response
  xml = xml || '';
  var index = xml.indexOf('<');
  if (index > 0) {
    xml = xml.slice(index);
  }

  var parser = new xml2js.Parser({normalize: false, trim: false});
  parser.parseString(xml, function (err, data) {
    if (err) {
      callback(err);
    } else {
      callback(null, data);
    }
  });
};