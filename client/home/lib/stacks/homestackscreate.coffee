kd = require 'kd'


module.exports = class HomeStacksCreate extends kd.CustomHTMLView



  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView-Stacks--create'

    super options, data

    @create = new kd.ButtonView
      cssClass : 'GenericButton HomeAppView-Stacks--createButton'
      title    : 'NEW STACK'
      callback : => @emit 'CreateButtonClick'


  pistachio: ->

    '''
    <h2>Create New Stack Template</h2>
    <p>Start a new stack script</p>
    {{> @create}}
    '''
