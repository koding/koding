React = require 'app/react'

module.exports = class ProfileText extends React.Component

  getDisplayName: ->

    { isExempt, profile } = @props.account
    { firstName, lastName, nickname } = profile

    troll = if isExempt then '(T)' else ''

    nicename = if firstName is '' and lastName is ''
    then "#{nickname} #{troll}"
    else "#{firstName} #{lastName} #{troll}"

    return nicename.trim()


  render: ->
    <span>{@getDisplayName()}</span>


