kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
classnames              = require 'classnames'
AvatarsView             = require './avatarsview'
AllParticipantsMenuView = require './allparticipantsmenuview'
InputWidget             = require 'activity/components/channelparticipantsinputwidget'

module.exports = class ChannelParticipantsView extends React.Component

  PREVIEW_COUNT     = 0
  MAX_PREVIEW_COUNT = 19

  @propTypes =
    query                             : React.PropTypes.string
    value                             : React.PropTypes.string
    visible                           : React.PropTypes.bool
    isParticipant                     : React.PropTypes.bool
    addNewParticipantMode             : React.PropTypes.bool
    showAllParticipants               : React.PropTypes.bool
    onNewParticipantButtonClick       : React.PropTypes.func.isRequired
    onShowMoreParticipantsButtonClick : React.PropTypes.func.isRequired
    channelId                         : React.PropTypes.string.isRequired
    participants                      : React.PropTypes.instanceOf immutable.Map
    items                             : React.PropTypes.instanceOf immutable.List


  @defaultProps =
    query                            : ''
    value                            : ''
    visible                          : no
    isParticipant                    : no
    addNewParticipantMode            : no
    showAllParticipants              : no
    selectedItem                     : null
    selectedIndex                    : null
    participants                     : immutable.Map()
    items                            : immutable.List()


  getPreviewCount: ->

    { participants } = @props

    diff = participants.size - MAX_PREVIEW_COUNT

    PREVIEW_COUNT = switch
      when diff is 0 then MAX_PREVIEW_COUNT
      when diff < 0 then participants.size
      else MAX_PREVIEW_COUNT - 1


  renderPreviewAvatars: ->

    return null  unless @props.participants

    participants = @props.participants.slice 0, @getPreviewCount()

    <AvatarsView
      isNicknameVisible   = { no }
      shouldTooltipRender = { yes }
      participants        = {participants}/>


  renderMoreCount: ->

    return null  unless @props.participants

    moreCount = @props.participants.size - PREVIEW_COUNT

    return null  unless moreCount > 0

    moreCount = Math.min moreCount, 99

    <div className='ChannelParticipantAvatars-singleBox'>
      <div
        ref='showMoreButton'
        className='ChannelParticipantAvatars-moreCount'
        onClick={@props.onShowMoreParticipantsButtonClick}>
        +{moreCount}
      </div>
    </div>


  renderAllParticipantsMenu: ->

    return null  unless @props.showAllParticipants
    return null  unless @props.participants

    <AllParticipantsMenuView
      ref          = 'AllParticipantsMenu'
      participants = {@props.participants.slice @getPreviewCount()} />


  getAddNewParticipantButtonClassNames: -> classnames
    'ChannelParticipantAvatars-newParticipantBox': yes
    'hidden' : not @props.isParticipant
    'cross'  : @props.addNewParticipantMode


  renderNewParticipantButton: ->

    <div className='ChannelParticipantAvatars-singleBox'>
      <div
        onClick   = { @props.onNewParticipantButtonClick }
        className = { @getAddNewParticipantButtonClassNames() }/>
    </div>


  renderAddNewParticipantInput: ->

    <InputWidget.Container
      ref                   = 'InputWidget'
      query                 = { @props.query }
      items                 = { @props.items }
      visible               = { @props.visible }
      channelId             = { @props.channelId }
      selectedItem          = { @props.selectedItem }
      selectedIndex         = { @props.selectedIndex }
      addNewParticipantMode = { @props.addNewParticipantMode } />


  getWrapperClassNames : -> classnames
    'ChannelParticipantAvatars' : yes
    'noParticipant'             : not @props.participants.size


  render: ->

    <div>
      <div className={@getWrapperClassNames()}>
        {@renderPreviewAvatars()}
        {@renderMoreCount()}
        {@renderNewParticipantButton()}
      </div>
      {@renderAddNewParticipantInput()}
      {@renderAllParticipantsMenu()}
    </div>


