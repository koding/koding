kd          = require 'kd'
React       = require 'kd-react'
immutable   = require 'immutable'
classnames  = require 'classnames'
DropupItem  = require 'activity/components/dropupitem'
Avatar      = require 'app/components/profile/avatar'
ProfileText = require 'app/components/profile/profiletext'

module.exports = class UserDropupItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item }    = @props
    account     = item.toJS()
    { profile } = account

    fullNameClass = classnames
      'UserDropupItem-fullName' : yes
      'hidden'                  : not (profile.firstName and profile.lastName)

    <DropupItem {...@props} className="UserDropupItem">
      <Avatar width='25' height='25' account={account} />
      <div className='UserDropupItem-names'>
        <span className='UserDropupItem-nickname'>
          {account.profile.nickname}
        </span>
        <span className={fullNameClass}>
          <ProfileText account={account} />
        </span>
      </div>
      <div className='clearfix' />
    </DropupItem>
