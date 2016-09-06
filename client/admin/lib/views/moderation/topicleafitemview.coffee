kd                     = require 'kd'
JView                  = require 'app/jview'
KDListItemView         = kd.ListItemView


module.exports = class TopicLeafItemView extends KDListItemView

  JView.mixin @prototype

  pistachio: ->
    data     = @getData()

    return """
      <div class="details">
        <p class="nickname">\#{{#(name)}}</p>
      </div>
      <div class='clear'></div>

    """
