kd = require 'kd'
React = require 'app/react'
cx = require 'classnames'

Machine = require 'app/remote-extensions/machine'

actions = require 'app/flux/environment/actions'

SidebarWidget = require './widget'
SidebarWidgetUser = require './widgetuser'
SidebarWidgetTitle = require './widgettitle'


module.exports = SharingWidget = ({ machine, coordinates }) ->

  text = if machine.getType() is Machine.Type.Collaboration
  then 'wants to collaborate with you on their VM.'
  else 'wants to share their VM with you'

  <SidebarWidget onClose={onClose} coordinates={coordinates}>

    <SidebarWidgetUser owner={machine.getOwner()} />
    <SidebarWidgetTitle children={text} />

    <Buttons>
      <Button type='reject' onClick={-> onReject machine} />
      <Button type='accept' onClick={-> onAccept machine} />
    </Buttons>

  </SidebarWidget>


Buttons = ({ children }) ->

  <div className='button-wrapper'>{children}</div>


Button = ({ type, children, onClick }) ->

  <button onClick={onClick} className={cx 'kdbutton', 'GenericButton', type}>
    <span className='button-title' children={type.toUpperCase()} />
  </button>


onReject = (machine) ->

  { sidebar } = kd.singletons

  sidebar.setInvited null
  actions.leaveMachine machine


onAccept = (machine) ->

  { sidebar } = kd.singletons

  sidebar.setInvited null
  actions.acceptInvitation machine


onClose = ->

  { sidebar } = kd.singletons

  sidebar.setInvited null
