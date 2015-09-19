kd                 = require 'kd'
Link               = require 'app/components/common/link'
React              = require 'kd-react'
classnames         = require 'classnames'
CreateChannelFlux  = require 'activity/flux/createchannel'
CreateChannelModal = require 'activity/components/createchannelmodal'

module.exports = class SidebarSection extends React.Component

  @defaultProps =
    onHeaderClick: kd.noop

  constructor: (options = {}, data) ->

    super options, data

    @state = { isModalOpen: no }


  onHeaderClick: -> @props.onHeaderClick()


  onClose: ->

    { actions } = CreateChannelFlux

    actions.channel.removeAllParticipants()
    actions.user.unsetInputQuery()
    @setState isModalOpen: no


  handleAddChannelButtonClick: (event) ->

    kd.utils.stopDOMEvent event
    @setState isModalOpen: yes


  getCreateChannelModalProps: ->

    isOpen             : @state.isModalOpen
    account            : @state.account
    onAbort            : @bound 'onClose'
    onClose            : @bound 'onClose'
    title              : @props.modalProps.title
    className          : @props.modalProps.className
    buttonConfirmTitle : @props.modalProps.buttonConfirmTitle


  renderAddChannelModal: ->

    <CreateChannelModal {...@getCreateChannelModalProps()} />


  renderHeader: ->

    <h4 className='SidebarSection-headerTitle' onClick={@bound 'onHeaderClick'}>
      {@props.title}
      <Link
        className = "SidebarSection-addChannelButton"
        onClick   = { @bound 'handleAddChannelButtonClick' }
      />
    </h4>


  render: ->

    <section className={classnames 'SidebarSection', @props.className}>
      <header className='SidebarSection-header'>
        {@renderHeader()}
      </header>
      <div className='SidebarSection-body'>
        {@props.children}
      </div>
      {@renderAddChannelModal()}
    </section>

