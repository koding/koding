var ace_commands = require('./ace-commands');
var ace_descriptions = require('./ace-descriptions');
var _ = require('underscore');
var tomf = require('./to-mousetrap');

// we only keep read-only shortcuts as hidden
var blacklist = [
  'passKeysToBrowser',
  'showSettingsMenu',
  'singleSelection',
  'occurisearch',
  'recenterTopBottom', 
  'iSearchBackwardsAndGo',
  'iSearchAndGo',
  'iSearch',
  'gotoline',
  'find'
];

var disabled = [
  'sortlines',
  'gotoline',
  'find',
  'showSettingsMenu'
];

var keys = {
  // default
  default: ace_commands.commands,
  // default multiselect
  defaultMultiSelect: ace_commands.defaultMultiSelectCommands,
  // multiselect
  multiSelect: ace_commands.multiSelectCommands,
  // incremental search
  iSearch: ace_commands.iSearchCommands,
  // incremental search start
  iSearchStart: ace_commands.iSearchStartCommands
};

function sanitize (list, acens) {
  return _.chain(list).map(function (value) {
    var readonly = value.readOnly || value.readonly || false;
    var hidden = false;
    if (blacklist.indexOf(value.name) != -1) {
      if (!readonly)
        return;
      else hidden = true;
    }

    var canonical = ['e#ace', acens, value.name].join('#');
    var binding;
    if (typeof value.bindKey == 'string') {
      binding = _.map(value.bindKey.split('|'), tomf);
    }
    else if (Array.isArray(value.bindKey)) {
      binding = _.map(value.bindKey, function (k) {
        if(!k) return null;
        return _.map(k.split('|'), tomf);
      });
    } else if(typeof value.bindKey == 'object') {
      binding = [];
      binding[0] = _.map(value.bindKey.mac.split('|'), tomf);
      binding[1] = _.map(value.bindKey.win.split('|'), tomf);
    }

    if (!binding)
      return null;

    if (binding.length == 1 && !Array.isArray(binding[0]))
      binding = [[binding[0]], [binding[0]]];

    var description = ace_descriptions[value.name];

    return {
      name: canonical,
      acens: acens,
      description: description,
      binding: binding,
      readonly: readonly,
      enabled: disabled.indexOf(value.name) == -1,
      hidden: hidden,
      options: {ace: true}
    };
  }).compact().value();
}

var out = [];
_.each(keys, function (value, key) {
  out.push(sanitize(value, key));
});
out = _.flatten(out);

console.log(JSON.stringify(out, null, 2));
