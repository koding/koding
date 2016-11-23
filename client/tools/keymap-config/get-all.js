var _ = require('underscore');

function fn (n) {
  n.name = n.name.split('#').slice(-1).join('')
  delete n.options;
  if (n.hidden == false)
    delete n.hidden;
  if (n.readonly == false)
    delete n.readonly;
  if (n.enabled == true)
    delete n.enabled;
  if (Array.isArray(n.binding)) {
    if (Array.isArray(n.binding[0])) {
      if (_.compact(n.binding[0]).length == 0)
        n.binding[0] = null;
    } else {
      n.binding[0] = null;
    }
    if (Array.isArray(n.binding[1])) {
      if (_.compact(n.binding[1]).length == 0)
        n.binding[1] = null;
    } else {
      n.binding[1] = null;
    }
  } else {
    delete n.binding;
  }

  if (_.compact(n.binding).length == 0)
    delete n.binding;
  return n;
}

var ace = require('./out/ace-bindings.json');
ace = ace.map(function (n) {
  n = fn(n);
  if (n.name == 'gotolineend') {
    n.binding[1] = _.without(n.binding[1], 'ctrl+e');
  }
  else if (n.name == 'golineup') {
    n.binding[1] = _.without(n.binding[1], 'ctrl+p');
  }
  return n;
});
ace = _.groupBy(ace, 'acens');
var ace_ = {};
_.each(ace, function (v, k) {
  ace_['ace_' + k] = v.map(function (j) {
    delete j.acens;
    return j;
  });
});
var editor = require('./out/editor-bindings.json');
editor = editor.map(fn);
var terminal = require('./out/terminal-bindings.json');
terminal = terminal.map(fn);
var workspace = require('./out/workspace-bindings.json');
workspace = workspace.map(fn);
var out = {
  editor: editor,
  terminal: terminal,
  workspace: workspace
};
_.extend(out, ace_);
console.log(JSON.stringify(out, null, 2));
