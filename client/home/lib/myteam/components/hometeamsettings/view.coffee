kd              = require 'kd'
React           = require 'kd-react'
List            = require 'app/components/list'
Encoder         = require 'htmlencode'


module.exports = class HomeTeamSettingsView extends React.Component


  onClickLogo: (event) ->

    @input.click()


  render: ->

    <div>
      <div className='HomeAppView--uploadLogo'>
        <TeamLogo team={@props.team} logopath={@props.logopath} callback={@bound 'onClickLogo'}/>
        <div className='uploadInputWrapper'>
          <GenericButtons canEdit={@props.canEdit} clickLogo={@props.onClickLogo} removeLogo={@props.onRemoveLogo} />
          <input ref={(input) => @input = input} accept='image/*' className='kdinput file' type='file' onChange={@props.onUploadInput} />
        </div>
      </div>
      <form>
        <div className='hor-flex'>
          <TeamName canEdit={@props.canEdit} title={@props.team.get 'title'} teamName={@props.teamName} callback={@props.onTeamNameChanged} />
          <TeamDomain slug={@props.team.get 'slug'} />
        </div>
        <ActionBar canEdit={@props.canEdit} callback={@props.onUpdate} onLeaveTeam={@props.onLeaveTeam}/>
      </form>
    </div>


GenericButtons = ({ canEdit, clickLogo, removeLogo }) ->

  if canEdit
    <div>
      <GenericButton className={'custom-link-view primary'} title={'UPLOAD LOGO'} callback={clickLogo} />
      <GenericButton className={'custom-link-view remove'} title={'REMOVE'} callback={removeLogo} />
    </div>
  else
    <div />


ActionBar = ({ canEdit, callback, onLeaveTeam }) ->

  className = unless canEdit then 'hidden' else ''
  className = kd.utils.curry 'custom-link-view primary fr', className

  <fieldset className='HomeAppView--ActionBar'>
    <LeaveTeam onLeaveTeam={onLeaveTeam}/>
    <GenericButton className={className} title={'SAVE CHANGES'} callback={callback}/>
  </fieldset>


LeaveTeam = ({ onLeaveTeam }) ->

  <GenericButton title={'LEAVE TEAM'} callback={onLeaveTeam} />


TeamDomain = ({ slug }) ->

  value = "#{Encoder.htmlDecode slug}.koding.com" ? ''

  <fieldset className='half TeamUrl'>
    <label>Koding URL</label>
    <input type='text' name='url', className='kdinput text js-teamDomain' disabled value={value} />
  </fieldset>


TeamName = ({ title, teamName, callback }) ->

  encode = if title then title else ''
  value = teamName or Encoder.htmlDecode encode

  <fieldset className='half'>
    <label>Team Name</label>
    <input type='text' name='title' className='kdinput text js-teamName' value={value} onChange={callback}/>
  </fieldset>


GenericButton = ({ className, title, callback }) ->

  className = kd.utils.curry 'HomeAppView--button', className
  <a className={className} href='#' onClick={callback}>
    <span className='title'>{title}</span>
  </a>


TeamLogo = ({ team, logopath, callback }) ->

  src = team.getIn(['customize', 'logo']) or logopath
  <img className='teamLogo' src={src} onClick={callback}/>
