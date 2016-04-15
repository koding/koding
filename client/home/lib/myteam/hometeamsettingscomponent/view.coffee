kd              = require 'kd'
React           = require 'kd-react'
List            = require 'app/components/list'
Encoder         = require 'htmlencode'


module.exports = class HomeTeamSettingsView extends React.Component

  renderSaveButton: ->

    className = unless @props.canEdit then 'hidden' else ''
    className = kd.utils.curry 'custom-link-view primary fr', className
    <Button className={className} title={'SAVE CHANGES'} callback={@props.onUpdate}/>


  renderTeamDomain: ->

    value = "#{Encoder.htmlDecode @props.team.get 'slug'}.koding.com" ? ''
    <input ref='teamDomain' type='text' name='url', className='kdinput text' disabled value={value} />


  renderTeamName: ->

    value = @props.teamName or Encoder.htmlDecode @props.team.get 'title' ? ''

    <input ref='teamName' type='text' name='title' className='kdinput text' value={value} onChange={@props.onTeamNameChanged}/>


  render: ->

    <div>
      <div className='HomeAppView--uploadLogo'>
        <TeamLogo team={@props.team} logopath={@props.logopath} callback={@props.onClickLogo}/>
        <div className='uploadInputWrapper'>
          <Button className={'custom-link-view primary'} title={'UPLOAD LOGO'} callback={@props.onClickLogo} />
          <Button className={'custom-link-view remove'} title={'REMOVE'} callback={@props.onRemoveLogo}/>
          <input ref='uploadInput' accept='image/*' className='kdinput file' type='file' onChange={@props.onUploadInput} />
        </div>
      </div>
      <form>
        <div className='hor-flex'>
          <fieldset className='half'>
            <label>Team Name</label>
            {@renderTeamName()}
          </fieldset>
          <fieldset className='half TeamUrl'>
            <label>Koding URL</label>
            {@renderTeamDomain()}
          </fieldset>
        </div>
        <fieldset className='HomeAppView--ActionBar'>
          <Button className={''} title={'DELETE TEAM'}, callback={kd.noop} />
          {@renderSaveButton()}
        </fieldset>
      </form>
    </div>


Button = ({ className, title, callback }) ->

  className = kd.utils.curry 'HomeAppView--button', className
  <a className={className} href='#' onClick={callback}>
    <span className='title'>{title}</span>
  </a>


TeamLogo = ({ team, logopath, callback }) ->

  src = team.getIn(['customize', 'logo']) or logopath
  <img className='teamLogo' src={src} onClick={callback}/>
