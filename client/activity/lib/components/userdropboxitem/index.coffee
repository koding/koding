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

    item = @props.item.toJS()

    <DropboxItem {...@props} className="DropboxItem-singleLine DropboxItem-separated UserDropboxItem">
      {
        if item.isMention
        then helper.renderMentionItem item
        else helper.renderUserItem item
      }
      <div className='clearfix' />
    </DropboxItem>


  helper =

    renderUserItem: (item) ->

      { profile }   = item
      fullNameClass = classnames
        'UserDropboxItem-fullName' : yes
        'hidden'                   : not (profile.firstName and profile.lastName)

      <div>
        <Avatar width='25' height='25' account={item} />
        <div className='UserDropboxItem-names'>
          <span className='UserDropboxItem-nickname'>
            {profile.nickname}
          </span>
          <span className={fullNameClass}>
            <ProfileText account={item} />
          </span>
        </div>
      </div>


    renderMentionItem: (item) ->

      <div className='UserDropboxItem-names'>
        <span className='UserDropboxItem-nickname'>
          {item.name}
        </span>
      </div>

