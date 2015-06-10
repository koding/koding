Style = require './style'

module.exports   = class StyledText

  @DEFAULT_STYLE = new Style

  constructor: (text, style) ->

    @text        = text
    @style       = style
    @spanForced  = no
    @node        = null


  getNode: ->

    unless @node?
      if not @style.isDefault() or @spanForced
        @node = global.document.createElement 'span'
        @node.appendChild global.document.createTextNode @text
        @updateNode()
      else
        @node = global.document.createTextNode @text

    return @node


  updateNode: ->

    for own attr, value of @style.getAttributes()
      @node.setAttribute attr, value
