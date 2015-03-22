var a = [];

function add (name, description, keys) {
  keys = keys.join('+');

  var winKeys = 'ctrl+' + keys;
  var macKeys = 'command+' + keys;
  var obj = {
    name: name,
    description: description,
    binding: [
      [ winKeys ],
      [ macKeys ]
    ],
    options: {
      custom: true,
      overrides_ace: true
    }
  }
  
  a.push(obj);
}


add('save', 'Save', ['s']);
add('saveas', 'Save As...', ['shift+s']);
add('gotoline', 'Go to Line', ['g']);
add('find', 'Find', ['f']);
add('findandreplace', 'Find and Replace', ['shift+f']);

console.log(JSON.stringify(a, null, 2));