kd = require 'kd'
JView = require 'app/jview'
showStackEditor = require 'app/util/showStackEditor'

module.exports = class HomeStacksCreate extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView-Stacks--create'

    super options, data

    @create = new kd.ButtonView
      cssClass : 'GenericButton HomeAppView-Stacks--createButton'
      title    : 'NEW STACK'
      callback : ->
        options.delegate.destroy()
        kd.singletons.router.handleRoute '/Stack-Editor/New'


  pistachio: ->

    '''
    <h2>Create New Stack Template</h2>
    <p>Start a new stack script</p>
    {{> @create}}
    '''
