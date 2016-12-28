kd = require 'kd'
React = require 'app/react'
Avatar = require 'app/components/profile/avatar'
whoami = require 'app/util/whoami'
immutable = require 'immutable'
ProfileText = require 'app/components/profile/profiletext'

module.exports = class SharedCredentialUsers extends React.Component

  @propTypes     =
    users        : React.PropTypes.instanceOf immutable.List
    onUserRemove : React.PropTypes.func

  @defaultProps  =
    users        : immutable.List()
    onUserRemove : kd.noop


  onUserRemove: (user) ->
    @props.onUserRemove user.getIn [ 'profile', 'nickname' ]

  renderUser: (user) ->

    <div className='shared-credential-users single-user'>
      <Avatar width=20 height=20 account={user} />
      <div className='profile-wrapper'>
        <ProfileText className='ProfileName' account={user} />
        <span className='close-icon' onClick={@lazyBound 'onUserRemove', user} />
      </div>
    </div>


  render: ->

    <div className='shared-credential-users'>
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
      {@renderUser whoami()}
    </div>
