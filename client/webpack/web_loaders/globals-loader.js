var glob = require('glob')
var path = require('path')
var loaderUtils = require('loader-utils')

module.exports = function(globals) {

  var clientPath = loaderUtils.parseQuery(this.query).clientPath
  throwUnless(
    clientPath,
    '`clientPath` option is not set on query. Check your `globals-loader`' +
    ' configuration in webpack.config.js'
  )

  var configFile = require(path.join(clientPath, '.config.json'))
  throwUnless(
    configFile,
    'The generated config file does not exist. Did you run `./configure`' +
    ' in koding root folder?'
  )

  var schemaFile = require(path.join(clientPath, '.schema.json'))
  throwUnless(
    configFile,
    'There is no bongo schema file on client folder. Did you run' +
    ' `make bongo_schema` in `client` folder?'
  )

  var manifests = glob.sync('*/bant.json', {
    cwd: clientPath,
    realpath: true
  })

  return enhanceGlobals(globals, manifests, configFile, schemaFile)
}

function throwUnless(condition, message) {
  if (!condition) throw new Error(message)
}

function enhanceGlobals(globals, manifests, configFile, schemaFile) {

  // we are using bant.json files to identify which folders are app.
  var modules = manifests.map(function (_path) {
    var manifest = require(_path)

    // Only ide app's name is all upper case (IDE) other app names will be only
    // capitalized (Stackeditor, Welcome, Dashboard, etc.)
    var name = manifest.name === 'ide' ?
      manifest.name.toUpperCase() :
      manifest.name.charAt(0).toUpperCase() + manifest.name.slice(1)

    // For some reason we don't like dashes in our apps, so remove them to be
    // backwards compatible.
    name = name.replace(/-/g, '')

    // for each app we are returning a configuration object that can be
    // injected into runtime.
    return {
      identifier: manifest.name,
      name: name,
      routes: manifest.routes,
      shortcuts: manifest.shortcuts,
    }
  })

  return [
    globals,
    'var g = global._globals || {}',
    'Object.keys(g).forEach(function(k) {',
    '  globals[k] = g[k];',
    '})',
    'globals["config"]["version"] = ' + JSON.stringify(configFile.rev) + ';',
    'globals["REMOTE_API"] = ' + JSON.stringify(schemaFile) + ';',
    'globals["modules"] = ' + JSON.stringify(modules) + ';',
  ].join('\n')
}
