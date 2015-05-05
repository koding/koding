lazyrouter           = require 'app/lazyrouter'
kd                   = require 'kd'
KodingAppsController = require 'app/kodingappscontroller'

addToHead = KodingAppsController.appendHeadElement.bind KodingAppsController

module.exports = -> lazyrouter.bind 'testrunner', (type, info, state, path, ctx) ->

  switch type
    when 10 then runTests()


runTests = ->

  document.body.innerHTML = ''
  mochaContainer = document.createElement 'div'
  mochaContainer.id = 'mocha'
  document.body.appendChild mochaContainer

  jsOptions =
    identifier : 'mocha'
    url        : 'https://cdnjs.cloudflare.com/ajax/libs/mocha/2.2.4/mocha.js'

  cssOptions =
    identifier : 'mocha-css'
    url        : 'https://cdnjs.cloudflare.com/ajax/libs/mocha/2.2.4/mocha.css'

  addToHead 'style', cssOptions, ->
    addToHead 'script', jsOptions, ->
      mocha.ui('bdd')
      mochaTests = require './require-tests'
      mocha.run()


