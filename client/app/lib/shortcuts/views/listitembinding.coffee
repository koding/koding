kd = require 'kd'
isNavigatorApple = require('app/util/isNavigatorApple')()

module.exports =

class SLIBindingView extends kd.View

  constructor: (options={}, data) ->

    options.tagName = 'keys'
    super options, data


  getBinding: ->
    if isNavigatorApple
    then return @data.binding[1]
    else return @data.binding[0]


  viewAppended: ->
    
    html = ''
    keys = @getBinding()[0]
    if 'string' is typeof keys
      keys = keys.split '+'
      keys.forEach (key) ->
        html += "<i>#{key}</i>"

    @setPartial html
