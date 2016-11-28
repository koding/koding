Promise = require 'bluebird'
addToHead = (args...) -> require('app/kodingappscontroller').appendHeadElement args...


module.exports.appendScripts = ->
  mochaOptions =
    identifier: 'mocha'
    url: 'https://cdnjs.cloudflare.com/ajax/libs/mocha/3.1.2/mocha.min.js'

  mochaCleanOptions =
    identifier: 'mocha-clean'
    url: 'https://cdn.rawgit.com/rstacruz/mocha-clean/v0.4.0/index.js'


  new Promise (resolve, reject) ->
    addToHead 'script', mochaOptions, ->
      addToHead 'script', mochaCleanOptions, resolve
