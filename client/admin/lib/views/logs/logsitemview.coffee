kd      = require 'kd'
JView   = require 'app/jview'
timeago = require 'timeago'


module.exports = class LogsItemView extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type or= 'member'

    super options, data


  pistachio: ->

    { createdAt } = @getData()

    """
      <div class="details">
        <p class="code">{code{#(message)}}</p>
        <p class="time">Logged #{timeago createdAt}</p>
      </div>
    """
