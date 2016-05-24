kd              = require 'kd'
React           = require 'kd-react'
List            = require 'app/components/list'
Encoder         = require 'htmlencode'
DEFAULT_SPINNER_PATH = '/a/images/logos/balls.gif'


module.exports = class HomeTeamSettingsView extends React.Component

  onClickLogo: (event) ->

    @input.click()  if @props.canEdit


  render: ->

    <div>
      <div className='HomeAppView--uploadLogo'>
        <TeamLogo
          team={@props.team}
          logopath={@props.logopath}
          loading={@props.loading}
          callback={@bound 'onClickLogo'} />
        <div className='uploadInputWrapper'>
          <GenericButtons
            canEdit={@props.canEdit}
            clickLogo={@props.onClickLogo}
            removeLogo={@props.onRemoveLogo} />
          <input ref={(input) => @input = input} accept='image/*' className='kdinput file' type='file' onChange={@props.onUploadInput} />
        </div>
      </div>
      <form>
        <div className='hor-flex'>
          <TeamName canEdit={@props.canEdit} title={@props.team.get 'title'} teamName={@props.teamName} callback={@props.onTeamNameChanged} />
          <TeamDomain slug={@props.team.get 'slug'} />
        </div>
        <ActionBar
          canEdit={@props.canEdit}
          callback={@props.onUpdate}
          onLeaveTeam={@props.onLeaveTeam}
          teamNameChanged={@props.teamNameChanged} />
      </form>
    </div>


GenericButtons = ({ canEdit, clickLogo, removeLogo }) ->

  if canEdit
    <div>
      <GenericButton className='custom-link-view primary' title='UPLOAD LOGO' callback={clickLogo} />
      <GenericButton className='custom-link-view remove' title='REMOVE' callback={removeLogo} />
    </div>
  else
    <div />


ActionBar = ({ canEdit, callback, onLeaveTeam, teamNameChanged }) ->

  className = unless canEdit then 'hidden' else ''
  className = kd.utils.curry 'custom-link-view fr', className
  className = kd.utils.curry className, 'primary'  if teamNameChanged

  <fieldset className='HomeAppView--ActionBar'>
    <LeaveTeam onLeaveTeam={onLeaveTeam}/>
    <GenericButton className=className title='CHANGE TEAM NAME' callback={callback}/>
  </fieldset>


LeaveTeam = ({ onLeaveTeam }) ->

  <GenericButton title={'LEAVE TEAM'} callback={onLeaveTeam} />


TeamDomain = ({ slug }) ->

  value = "#{Encoder.htmlDecode slug}.koding.com" ? ''

  <fieldset className='half TeamUrl'>
    <label>Koding URL</label>
    <input type='text' name='url', className='kdinput text js-teamDomain' disabled value={value} />
  </fieldset>


TeamName = ({ canEdit, title, teamName, callback }) ->

  encode = if title then title else ''
  value = teamName or Encoder.htmlDecode encode

  <fieldset className='half'>
    <label>Team Name</label>
    <TeamNameInputArea canEdit={canEdit} value={value} callback={callback} />
  </fieldset>


TeamNameInputArea = ({ canEdit, value, callback }) ->

  if canEdit
    <input
      type='text'
      name='title'
      value={value}
      className='kdinput text js-teamName'
      onChange={callback} />
  else
    <input
      type='text'
      name='title'
      value={value}
      disabled={not canEdit}
      className='kdinput text js-teamName'
      onChange={callback} />


GenericButton = ({ className, title, callback }) ->

  className = kd.utils.curry 'HomeAppView--button', className
  <a className={className} href='#' onClick={callback}>
    <span className='title'>{title}</span>
  </a>


TeamLogo = ({ team, logopath, loading, callback }) ->

  src = team.getIn(['customize', 'logo']) or logopath
  src = DEFAULT_SPINNER_PATH  if loading
  <img className='teamLogo' src={src} onClick={callback} />

