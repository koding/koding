var makeGlobals, stringify;

var glob = require('glob')
var path = require('path')

var configFile = require('../../.config.json')

var aceBasePath = 'a/p/p/thirdparty/ace'

var aceConfig = {
  basePath   : aceBasePath,
  themePath  : aceBasePath,
  modePath   : aceBasePath,
  workerPath : aceBasePath,
}

module.exports = function(globals) {
  this.cacheable();

  globals = makeGlobals(globals, configFile);
  console.log('globals: globals are compiled')

  return globals
};

makeGlobals = function(globals, configFile) {
  return [
    globals,
    'var g = global._globals || {}',
    'Object.keys(g).forEach(function(k) {',
    '  globals[k] = g[k];',
    '})',
    'globals["acePath"] = "' + aceBasePath + '/_ace.js";',
    'globals["aceConfig"] = ' + JSON.stringify(aceConfig) + ';',
    'globals["config"]["version"] = ' + JSON.stringify(configFile.rev) + ';',
    'globals["REMOTE_API"] = ' + JSON.stringify(configFile.schema) + ';',
  ].join('\n')
};




