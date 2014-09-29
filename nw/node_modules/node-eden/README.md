node-eden
=========

> "And Adam gave names to all cattle, and to the fowl of the air, and to every beast of the field;" Genesis 2:20a

A node.js name generator.

##Installation

```
$ npm install node-eden
```

##Usage

```javascript
var eden = require('eden'),
  word = eden.word(), // word is now "fox" or some other word from the list
  him = eden.adam(),  // him is now a male first name e.g., "Aaron"
  her = eden.eve();   // her is now a female first name e.g., "Anna"
```

##Methods

The module provides 3 methods, each randomly picking a unique word from a different list.

###word()

Get a unique word from the list of ~45K words, see `lib/words.js`. Each word will be randomly chosen, and unique
until the list is exhausted, then it will start again.

###adam()

Get a unique male first name the list of ~4K male names, see `lib/male-names.js`. Each name will be randomly chosen, and unique
until the list is exhausted, then it will start again.

###eve()

Get a unique female name from the list of ~5K female names, see `lib/female-names.js`. Each name will be randomly chosen, and unique
until the list is exhausted, then it will start again.

##License

###Word Lists

See `lib/aaREADME.txt` for information about the word lists used in this module, which are modified versions of the
files found in http://www.gutenberg.org/ebooks/3201.

###Source Code

Copyright 2013 David Humphrey <david.humphrey@senecacollege.ca>

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
