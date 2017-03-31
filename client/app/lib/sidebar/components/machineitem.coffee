React = require 'react'
cx = require 'classnames'
Link = require 'app/components/common/link'

SharingWidget = require './sharingwidget'
LeavingWidget = require './leavingwidget'
ManagedMachineWidget = require './managedmachinewidget'

module.exports = SidebarMachineItem = (props) ->

  { leaving, selected, hasSettings, hasProgress, invited, managed
    status, percentage, coordinates, machine
    itemDidMount, onSettingsClick, onMachineClick } = props

  <Wrapper status={status} selected={selected}>

    <MachineLink itemDidMount={itemDidMount} onClick={onMachineClick}>
      <Icon status={status} />

      <Title machine={machine} />

      {hasProgress and
        <ProgressBar percentage={percentage} /> }

      {hasSettings and
        <SettingsIcon
          machine={machine}
          onClick={onSettingsClick} /> }

    </MachineLink>

    {leaving and
      <LeavingWidget
        machine={machine}
        coordinates={coordinates} /> }

    {invited and
      <SharingWidget
        key={machine._id}
        coordinates={coordinates}
        machine={machine} /> }

    {managed and
      <ManagedMachineWidget
        machine={machine}
        coordinates={coordinates} /> }

  </Wrapper>


Wrapper = ({ status, selected, children }) ->
  className = cx ['SidebarMachinesListItem', status, {
    'active': selected
  }]

  <div className={className}>{children}</div>


Title = ({ machine }) ->
  <span
    className='SidebarListItem-title'
    children={machine.getTitle()} />


Icon = ({ status }) ->
  <cite
    className="SidebarListItem-icon"
    title={"Machine status: #{status}"} />


MachineLink = ({ itemDidMount, onClick, children }) ->
  <Link
    ref={itemDidMount}
    className="SidebarMachinesListItem--MainLink"
    onClick={onClick}
    children={children} />


ProgressBar = ({ percentage }) ->

  className = cx {
    'SidebarListItem-progressbar': yes
    'full': percentage is 100
  }

  <div className={className}>
    <cite style={width: "#{percentage}%"} />
  </div>


SettingsIcon = ({ machine, onClick }) ->
  <span
    className='MachineSettings'
    onClick={onClick} />
