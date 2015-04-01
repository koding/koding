kd = require 'kd'
isNavigatorApple = require('app/util/isNavigatorApple')()

module.exports =

class SLIBindingView extends kd.View

  constructor: (options={}, data) ->

    options.cssClass = 'keys'

    super options, data

    @addSubView @input = new kd.InputView
      cssClass    : 'hidden'
      placeholder : @getRepresentation yes
      keydown : (event) =>
        kd.utils.stopDOMEvent event
        # take this part apart
        # make os specific
        value = ''
        if event.metaKey  then value += 'cmd '
        if event.ctrlKey  then value += 'ctrl '
        if event.altKey   then value += 'alt '
        if event.shiftKey then value += 'shift '

        value += String.fromCharCode event.keyCode ? event.charCode
        value = value.trim()

        @input.setValue value
        # poc code - SY
        @data.binding[0][0] = value.toLowerCase().replace /\s/g, '+'
        @data.binding[1][0] = value.toLowerCase().replace /\s/g, '+'

        @representation.updatePartial @getRepresentation()
        @emit 'KeybindingUpdated'

        return no

    @addSubView @representation = new kd.CustomHTMLView
      tagName : 'span'
      partial : @getRepresentation()


  showEditMode: ->

    @input.show()
    @input.setFocus()
    @representation.hide()


  hideEditMode: ->

    @input.hide()
    @representation.show()


  getBinding: ->
    if isNavigatorApple
    then return @data.binding[1]
    else return @data.binding[0]


  getRepresentation: (bare) ->

    return null  unless 'string' is typeof keys = @getBinding()[0]

    html = ''
    keys = keys.split '+'
    keys.forEach (key) ->
      if bare
      then html += "#{key} "
      else html += "<i>#{key}</i>"

    return html.trim()
