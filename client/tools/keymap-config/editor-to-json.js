var keyBindings = [
  ['save', 'Save', [['ctrl+s'], ['command+s']]],
  ['saveas', 'Save As...', [['ctrl+shift+s'], ['command+shift+s']]],
  ['gotoline', 'Go to Line', [['ctrl+g'], ['command+g']]],
  ['find', 'Find', [['ctrl+f'], ['command+f']]],
  ['findandreplace', 'Find and Replace', [['ctrl+shift+f'], ['command+shift+f']]]
];

var _ = require('underscore');

var out = _.map(keyBindings, function (val) {
  return {
    name: 'e#' + val[0],
    description: val[1],
    binding: val[2],
    readonly: false,
    enabled: true,
    hidden: false,
    options: {
      ace: true
    }
  };
});

console.log(JSON.stringify(out, null, 2));
