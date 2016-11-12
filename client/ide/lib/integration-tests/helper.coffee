Promise = require 'bluebird'
addToHead = (args...) -> require('app/kodingappscontroller').appendHeadElement args...


module.exports.appendScripts = ->
  mochaOptions =
    identifier: 'mocha'
    url: 'https://cdnjs.cloudflare.com/ajax/libs/mocha/2.2.4/mocha.js'

  shouldOptions =
    identifier: 'should'
    url: 'https://cdnjs.cloudflare.com/ajax/libs/should.js/11.1.1/should.min.js'

  new Promise (resolve, reject) ->
    addToHead 'script', mochaOptions, ->
      addToHead 'script', shouldOptions, resolve
