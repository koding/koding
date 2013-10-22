'use strict';
var protocol = require('./amqp-definitions-0-9-1');
// a look up table for methods recieved
// indexed on class id, method id
var methodTable = {};

// methods keyed on their name
var methods = {};

// classes keyed on their index
var classes = {};

(function () { // anon scope for init
  //debug("initializing amqp methods...");

  for (var i = 0; i < protocol.classes.length; i++) {
    var classInfo = protocol.classes[i];
    classes[classInfo.index] = classInfo;
    for (var j = 0; j < classInfo.methods.length; j++) {
      var methodInfo = classInfo.methods[j];
      
      var name = classInfo.name + 
        methodInfo.name[0].toUpperCase() + 
        methodInfo.name.slice(1);
      //debug(name);
      
      var method = { 
        name: name, 
        fields: methodInfo.fields, 
        methodIndex: methodInfo.index, 
        classIndex: classInfo.index
      };
      
      if (!methodTable[classInfo.index]) methodTable[classInfo.index] = {};
      methodTable[classInfo.index][methodInfo.index] = method;
      methods[name] = method;
    }
  }
})(); // end anon scope

module.exports = {methods: methods, classes: classes, methodTable: methodTable};