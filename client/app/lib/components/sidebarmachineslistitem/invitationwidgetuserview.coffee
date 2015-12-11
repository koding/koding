React = require 'kd-react'
Link  = require 'app/components/common/link'


module.exports = class InvitationWidgetUserView extends React.Component

  @defaultProps =
    link      : '#'
    source    : ''
    size      :
      width   : 30
      height  : 30


  render: ->
    <div className='InvitationWidget-UserView'>
      <Link
        className='InvitationWidget-Link'
        href={@props.link}>
        <img src={@props.source} width={@props.size.width} height={@props.size.height} />
      </Link>
      <div className='InvitationWidget-UserDetail'>
        <span className='InvitationWidget-FullName'>Gokhan Turunc</span>
          <span className='InvitationWidget-NickName'>@turunc</span>
      </div>
    </div>
