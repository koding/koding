kd = require 'kd'

module.exports =

class ShortcutsListItem extends kd.ListItemView

  constructor: (options={}, model) ->
    
    options.type or= 'sidebar-item'
    options.tagName or= 'a'
    options.cssClass ='clearfix'

    super options, model

  pistachio: ->

    """
    {span.ttag{#(name)}}
    """

    
