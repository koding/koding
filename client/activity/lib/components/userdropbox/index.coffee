kd                     = require 'kd'
React                  = require 'kd-react'
immutable              = require 'immutable'
classnames             = require 'classnames'
Dropbox                = require 'activity/components/dropbox/portaldropbox'
UserDropboxItem        = require 'activity/components/userdropboxitem'
UserMentionDropboxItem = require 'activity/components/userdropboxitem/usermentiondropboxitem'
DropboxWrapperMixin    = require 'activity/components/dropbox/dropboxwrappermixin'
ChatInputFlux          = require 'activity/flux/chatinput'
ImmutableRenderMixin   = require 'react-immutable-render-mixin'
isWithinCodeBlock      = require 'app/util/isWithinCodeBlock'
findNameByQuery        = require 'activity/util/findNameByQuery'


module.exports = class UserDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    users          : immutable.List()
    userMentions   : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null


  isActive: ->

    { users, userMentions, visible } = @props
    return (users.size + userMentions.size) > 0 and visible


  hasSingleItem: ->

    { users, userMentions, visible } = @props
    return (users.size + userMentions.size) is 1


  hasUsers: -> @props.users.size > 0


  formatSelectedValue: ->

    { selectedItem, query } = @props
    names = selectedItem.get('names')

    if names
      name = findNameByQuery(names.toJS(), query) ? names.first()
    else
      name = selectedItem.getIn ['profile', 'nickname']

    return "@#{name}"


  getItemKey: (item) ->

    names = item.get('names')

    if names then names.first() else item.get '_id'


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.user.setVisibility stateId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.user.moveToNextIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.user.moveToPrevIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord, value, position } = textData
    return no  unless currentWord
    return no  if isWithinCodeBlock value, position

    matchResult = currentWord.match /^@(.*)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.user.setQuery stateId, query
    ChatInputFlux.actions.user.setVisibility stateId, yes

    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.user.setSelectedIndex stateId, index


  renderUserList: ->

    { users, selectedIndex } = @props

    users.map (item, index) =>
      isSelected = index is selectedIndex

      <UserDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  renderMentionListHeader: ->

    { userMentions } = @props
    return  if userMentions.size is 0 or not @hasUsers()

    <div className='Dropbox-header UserDropbox-groupsHeader DropboxItem-separated'>
      Groups
    </div>


  renderMentionList: ->

    { users, userMentions, selectedIndex } = @props

    userMentions.map (item, index) =>
      index += users.size
      isSelected = index is selectedIndex

      <UserMentionDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    { users } = @props
    title     = if @hasUsers() then 'People' else 'Groups'

    <Dropbox
      className = 'UserDropbox'
      visible   = { @isActive() }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      title     = { title }
      ref       = 'dropbox'
    >
      { @renderUserList() }
      { @renderMentionListHeader() }
      { @renderMentionList() }
    </Dropbox>

