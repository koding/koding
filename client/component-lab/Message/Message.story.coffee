React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'

Message = require './Message'

storiesOf 'Message', module
  .add 'default', ->
    description = '
      We were unable to verify your card. Please check the details you entered
      below and try again.
    '
    <Message
      onCloseClick={action 'onCloseClick'}
      type='danger'
      title='Credit Card Error'
      description={description} />

  .add 'with icon', ->

    description = '
      We were unable to verify your card. Please check the details you entered
      below and try again.
    '

    IconComponent = ->
      one = require 'app/sprites/1x/cc-error.png'
      two = require 'app/sprites/2x/cc-error.png'

      imgOne = new Image
      imgOne.src = one
      { naturalHeight: height, naturalWidth: width } = imgOne

      src = if global.devicePixelRatio >= 2 then two else one

      <span><img src={src} style={{height, width}} /></span>

    <Message
      IconComponent={IconComponent}
      type='danger'
      title='Credit Card Error'
      description={description} />
