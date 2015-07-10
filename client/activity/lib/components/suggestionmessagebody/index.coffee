React       = require 'kd-react'
MessageBody = require 'activity/components/common/messagebody'

module.exports = class SuggestionMessageBody extends MessageBody

  formatSource: ->

    html = super()

    { query } = @props
    regExp = new RegExp query, 'gi'
    html = html.replace regExp, (str) ->
      "<span class='SuggestionMessageBody-query'>#{str}</span>"
    return html