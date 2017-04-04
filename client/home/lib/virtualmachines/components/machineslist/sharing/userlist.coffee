kd          = require 'kd'
immutable   = require 'immutable'
React       = require 'app/react'
List        = require 'app/components/list'
Avatar      = require 'app/components/profile/avatar'
ProfileText = require 'app/components/profile/profiletext'


module.exports = class SharingUserList extends React.Component

  @propTypes     =
    users        : React.PropTypes.array
    onUserRemove : React.PropTypes.func

  @defaultProps  =
    users        : []
    onUserRemove : kd.noop


  onUserRemove: (user) ->

    @props.onUserRemove user.getAt 'profile.nickname'


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.users.length


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    user = @props.users[rowIndex]

    <div>
      <Avatar width=32 height=32 account={user} />
      <ProfileText className='ProfileName' account={user} />
      <span className='remove' onClick={@lazyBound 'onUserRemove', user} />
    </div>


  renderEmptySectionAtIndex: ->

    <div className='NoItem'>This VM has not yet been shared with anyone.</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
      sectionClassName='UserList'
      rowClassName='UserListItem'
    />
