kd          = require 'kd'
React       = require 'kd-react'
immutable   = require 'immutable'
classnames  = require 'classnames'
DropboxItem = require 'activity/components/dropboxitem'
Avatar      = require 'app/components/profile/avatar'
ProfileText = require 'app/components/profile/profiletext'

module.exports = class UserDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item }    = @props
    account     = item.toJS()
    { profile } = account

    fullNameClass = classnames
      'UserDropboxItem-secondaryText' : yes
      'hidden'                        : not (profile.firstName and profile.lastName)

    <DropboxItem {...@props} className="DropboxItem-singleLine DropboxItem-separated UserDropboxItem">
      <Avatar width='25' height='25' account={account} />
      <div className='UserDropboxItem-names'>
        <span className='UserDropboxItem-nickname'>
          {account.profile.nickname}
        </span>
        <span className={fullNameClass}>
          <ProfileText account={account} />
        </span>
      </div>
      <div className='clearfix' />
    </DropboxItem>

