kd          = require 'kd'
immutable   = require 'immutable'
React       = require 'app/react'
List        = require 'app/components/list'
Avatar      = require 'app/components/profile/avatar'
ProfileText = require 'app/components/profile/profiletext'


module.exports = class SharingUserList extends React.Component

  @propTypes     =
    users        : React.PropTypes.instanceOf immutable.List
    onUserRemove : React.PropTypes.func

  @defaultProps  =
    users        : immutable.List()
    onUserRemove : kd.noop


  onUserRemove: (user) ->

    @props.onUserRemove user.getIn [ 'profile', 'nickname' ]


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.users.toList().size


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    user = @props.users.toList().get rowIndex
    <div>
      <Avatar width=32 height=32 account={user.toJS()} />
      <ProfileText className='ProfileName' account={user.toJS()} />
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
