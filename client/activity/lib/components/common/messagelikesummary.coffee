kd                   = require 'kd'
React                = require 'kd-react'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class MessageLikeSummary extends React.Component

  render: ->

    { message, className } = @props

    actorsCount = message.getIn ['interactions', 'like', 'actorsCount']

    return null  unless actorsCount

    <div className={kd.utils.curry 'MessageLikeSummary', className}>
      {summarizeLikes message}
    </div>


summarizeLikes = (message) ->

  previews = message.getIn ['interactions', 'like', 'actorsPreview']
  count    = message.getIn ['interactions', 'like', 'actorsCount']

  actorsCount = Math.max count, previews.size

  linkCount = switch
    when actorsCount > 3 then 2
    else previews.size

  children = []
  counter = 0

  previews.slice(0, linkCount).forEach (preview, index) ->

    origin = originify preview, index
    children.push(
      <ProfileLinkContainer key={index} origin={origin}>
        <ProfileText />
      </ProfileLinkContainer>
    )
    children.push(
      <span key="seperator-#{index}">
        {getSeparator actorsCount, linkCount, counter}
      </span>
    )

    counter++

  if (diff = actorsCount - linkCount) > 0
    children.push(
      <a href="#" key="suffix">
        <strong>{diff} other{if diff > 1 then 's' else ''}</strong>
      </a>
    )

  children.push(
    <span key="last-words"> liked this.</span>
  )

  return children


getSeparator = (actorsCount, linkCount, index) ->

  switch
    when (linkCount - index) is (if actorsCount - linkCount then 1 else 2)
      ' and '
    when index < (linkCount - 1)
      ', '


originify = (preview, index) ->

  origin = { constructorName: 'JAccount', id: index }

  if preview
    origin = preview.toJS()

  return origin
