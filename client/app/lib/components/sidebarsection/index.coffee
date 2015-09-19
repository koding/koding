kd = require 'kd'
React = require 'kd-react'
classnames = require 'classnames'


module.exports = class SidebarSection extends React.Component

  @defaultProps =
    onHeaderClick: kd.noop

  onHeaderClick: -> @props.onHeaderClick()


  onClose: ->

    { actions } = CreateChannelFlux

    actions.channel.removeAllParticipants()
    actions.user.unsetInputQuery()
    @setState isModalOpen: no





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
      <header className="SidebarSection-header">
        {@renderHeader()}
      </header>
      <div className="SidebarSection-body">
        {@props.children}
      </div>
    </section>
