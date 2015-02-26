var _ = require('underscore');
var keymap = require('./out/ace-bindings.json');
keymap = keymap.concat(require('./out/editor-bindings.json'));
keymap = keymap.concat(require('./out/terminal-bindings.json'));
keymap = keymap.concat(require('./out/workspace-bindings.json'));

function fn (n, v, i) {
  if (!v.binding[n]) return;
  var collision;
  var f = _.find(keymap, function (suspect, j) {
    if (!suspect.binding[n] || j == i) return;
    var test = _.intersection(suspect.binding[n], v.binding[n]);
    collision = test;
    if (test.length) return true;
  });
  if (f) {
    if (v.name.substr(0, 5) == 'e#ace' && f.name.substr(0, 5) == 'e#ace')
      return;
    console.log('-', collision[0]);
    console.log('  -', v.description, '(' + v.name + ')', 'readonly: ' + v.readonly);
    console.log('  -', f.description, '(' + f.name + ')', 'readonly: ' + v.readonly);
    console.log('');
  }
}

console.log('# collisions\n');
console.log('this shows only first found collision, check again after you resolved this batch.\n')

console.log('# win collisions\n');
keymap.forEach(fn.bind(fn, 0));

console.log('\n# mac collisions\n');
keymap.forEach(fn.bind(fn, 1));
