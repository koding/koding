kd                     = require 'kd'
JView                  = require 'app/jview'
KDButtonView           = kd.ButtonView
KDListItemView         = kd.ListItemView
KDCustomHTMLView       = kd.CustomHTMLView


module.exports = class TopicItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'channel'

    super options, data

  pistachio: ->
    data     = @getData()
    topicname = "mehmetali"

    return """
      <div class="details">
        {{> @avatar}}
        <p class="nickname">@#{topicname}</p>
      </div>

    """
