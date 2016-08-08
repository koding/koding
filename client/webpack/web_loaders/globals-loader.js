var makeGlobals, stringify;

var glob = require('glob')
var path = require('path')

var CLIENT_PATH = path.join(__dirname, '../../')
var configFile = require('../../.config.json')
var schemaFile = require('../../.schema.json')

var manifests = glob.sync('*/bant.json', {
  cwd: CLIENT_PATH,
  realpath: true
}).map(require)

var modules = manifests.map(function(manifest) {

  var name = manifest.name === 'ide' ?
    manifest.name.toUpperCase() :
    manifest.name.charAt(0).toUpperCase() + manifest.name.slice(1)

  name = name.replace(/-/g, '')

  return {
    identifier: manifest.name,
    name: name,
    routes: manifest.routes,
    shortcuts: manifest.shortcuts,
    style: '/a/p/p/' + configFile.rev + '/' + manifest.name + '.css'
  }
})

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
    'globals["REMOTE_API"] = ' + JSON.stringify(schemaFile) + ';',
    'globals["modules"] = ' + JSON.stringify(modules) + ';',
  ].join('\n')
};

