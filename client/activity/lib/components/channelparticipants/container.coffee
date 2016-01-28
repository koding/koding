kd             = require 'kd'
View           = require './view'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
isNodeInRoot   = require 'app/util/isNodeInRoot'
KDReactorMixin = require 'app/flux/base/reactormixin'

module.exports = class ChannelParticipantsContainer extends React.Component

  @propTypes =
    channelThread : React.PropTypes.instanceOf immutable.Map
    participants  : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    channelThread : immutable.Map()
    participants  : immutable.Map()


  constructor: (props) ->

    super

    @state =
      showAllParticipants   : no
      addNewParticipantMode : no


  componentWillReceiveProps: (nextProps) ->

    channelId    = @props.channelThread.get 'channelId'
    oldChannelId = nextProps.channelThread.get 'channelId'

    @setState { addNewParticipantMode: no } if channelId isnt oldChannelId


  getDataBindings: ->

    { getters } = ActivityFlux

    return {
      query              : getters.channelParticipantsSearchQuery
      dropdownUsers      : getters.channelParticipantsInputUsers
      selectedItem       : getters.channelParticipantsSelectedItem
      selectedIndex      : getters.channelParticipantsSelectedIndex
      dropdownVisibility : getters.channelParticipantsDropdownVisibility
    }


  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleOutsideMouseClick'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleOutsideMouseClick'


  handleOutsideMouseClick: (event) ->

    { view } = @refs

    return  unless view.refs.AllParticipantsMenu

    target             = event.target
    moreButtonEl       = ReactDOM.findDOMNode view.refs.showMoreButton
    participantsMenuEl = ReactDOM.findDOMNode view.refs.AllParticipantsMenu

    if ((isNodeInRoot target, moreButtonEl) or (isNodeInRoot target, participantsMenuEl))
      return

    event.stopPropagation()
    @setState { showAllParticipants: no }


  onNewParticipantButtonClick: ->

    if @state.addNewParticipantMode is yes
    then @setState { addNewParticipantMode: no }
    else
      @setState { addNewParticipantMode: yes }, ->
        @refs.view.refs.InputWidget.focusOnInput()


  onShowMoreParticipantsButtonClick: (event) ->

    event.stopPropagation()

    @setState { showAllParticipants: not @state.showAllParticipants }


  render: ->

    isParticipant = @props.channelThread.getIn ['channel', 'isParticipant']

    <View
      ref                               = 'view'
      query                             = { @state.query }
      isParticipant                     = { isParticipant }
      participants                      = { @props.participants }
      selectedItem                      = { @state.selectedItem }
      items                             = { @state.dropdownUsers }
      selectedIndex                     = { @state.selectedIndex }
      visible                           = { @state.dropdownVisibility }
      showAllParticipants               = { @state.showAllParticipants }
      addNewParticipantMode             = { @state.addNewParticipantMode }
      channelId                         = { @props.channelThread.get 'channelId' }
      onNewParticipantButtonClick       = { @bound 'onNewParticipantButtonClick' }
      onShowMoreParticipantsButtonClick = { @bound 'onShowMoreParticipantsButtonClick' }/>


React.Component.include.call ChannelParticipantsContainer, [KDReactorMixin]

