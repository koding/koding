kd                     = require 'kd'
JView                  = require 'app/jview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView


module.exports = class TopicLeafItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    
    super options, data

  pistachio: ->
    data     = @getData()
    type     = 'Type'
    
    return """
      <div class="details">
        <p class="nickname">#{data.name}</p>
      </div>
      <div class='clear'></div>

    """