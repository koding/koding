kd              = require 'kd'
React           = require 'app/react'
List            = require 'app/components/list'
cdnize          = require 'app/util/cdnize'
Encoder         = require 'htmlencode'
DEFAULT_SPINNER_PATH = '/a/images/logos/loader.svg'


module.exports = class HomeTeamSettingsView extends React.Component

  onClickLogo: (event) ->

    @input.click()  if @props.canEdit


  render: ->

    <div>
      <div className='HomeAppView--uploadLogo'>
        <TeamLogo
          team={@props.team}
          canEdit={@props.canEdit}
          loading={@props.loading}
          callback={@bound 'onClickLogo'} />
        <div className='uploadInputWrapper'>
          <GenericButtons
            team={@props.team}
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


GenericButtons = ({ team, canEdit, clickLogo, removeLogo }) ->

  source = team.getIn(['customize', 'logo'])
  className = 'custom-link-view remove hidden'
  title = 'UPLOAD LOGO'

  if source
    className = 'custom-link-view remove'
    title = 'CHANGE LOGO'

  if canEdit
    <div>
      <GenericButton className='custom-link-view primary' title={title} callback={clickLogo} />
      <GenericButton className={className} title='REMOVE LOGO' callback={removeLogo} />
    </div>
  else
    <div />


ActionBar = ({ canEdit, callback, onLeaveTeam, teamNameChanged }) ->

  className = unless canEdit then 'hidden' else ''
  className = kd.utils.curry 'custom-link-view fr', className
  className = kd.utils.curry className, 'primary'  if teamNameChanged

  <fieldset className='HomeAppView--ActionBar'>
    <LeaveTeam onLeaveTeam={onLeaveTeam}/>
    <GenericButton className={className} title={'CHANGE TEAM NAME'} callback={callback}/>
  </fieldset>


LeaveTeam = ({ onLeaveTeam }) ->

  <GenericButton className='fl' title={'LEAVE TEAM'} callback={onLeaveTeam} />


TeamDomain = ({ slug }) ->

  value = "#{Encoder.htmlDecode slug}.koding.com" ? ''

  <fieldset className='half TeamUrl'>
    <label>Koding URL</label>
    <input type='text' name='url', className='kdinput text js-teamDomain' disabled value={value} />
  </fieldset>


TeamName = ({ canEdit, title, teamName, callback }) ->

  encode = if title then title else ''
  value = teamName ? Encoder.htmlDecode encode

  className = if canEdit then 'half' else 'half TeamName'

  <fieldset className={className}>
    <label>Team Name</label>
    <TeamNameInputArea canEdit={canEdit} value={value} callback={callback} />
  </fieldset>


TeamNameInputArea = ({ canEdit, value, callback }) ->

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


TeamLogo = ({ team, canEdit, loading, callback }) ->

  src = team.getIn(['customize', 'logo'])
  src = DEFAULT_SPINNER_PATH  if loading
  src = cdnize src

  unless src
    styles = {}
  else
    styles =
      backgroundImage : "url('#{src}')"
      backgroundSize : 'contain'
      backgroundPosition : 'center'

  className = 'teamLogo-wrapper'
  className = 'teamLogo-wrapper member'  unless canEdit

  <div className={className} onClick={callback} style={styles}>
  </div>
