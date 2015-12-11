kd                   = require 'kd'
React                = require 'kd-react'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class MessageLikeSummary extends React.Component

  render: ->
    <div className={kd.utils.curry 'MessageLikeSummary', @props.className}>
      {summarizeLikes @props.message}
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
      <span>
        {getSeparator actorsCount, linkCount, counter}
      </span>
    )

    counter++

  if (diff = actorsCount - linkCount) > 0
    children.push(
      <a href="#">
        <strong>{diff} other{if diff > 1 then 's' else ''}</strong>
      </a>
    )

  children.push(
    <span> liked this.</span>
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

