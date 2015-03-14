kd    = require 'kd'
JView = require 'app/jview'

module.exports =

class ShortcutsListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options={}, model) ->
    
    options.type or= 'sidebar-item'
    options.tagName or= 'a'
    options.cssClass ='clearfix'

    super options, model

  pistachio: ->

    """
    {span.ttag{#(name)}}
    """

    
