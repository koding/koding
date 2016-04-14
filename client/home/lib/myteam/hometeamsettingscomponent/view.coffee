kd              = require 'kd'
React           = require 'kd-react'
List            = require 'app/components/list'
Encoder         = require 'htmlencode'


module.exports = class HomeTeamSettingsView extends React.Component

  renderButton: (cssClass, title, callback) ->
    
    className = kd.utils.curry 'HomeAppView--button', cssClass
    <a className={className} href='#' onClick={callback}>
      <span className='title'>{title}</span>
    </a>
    
    
  renderUploadInput: ->
    
    <input ref='uploadInput' accept='image/*' className='kdinput file' type='file' onChange={@props.onUploadInput} />
    
    
  renderLogo: ->
    
    src = @props.team.getIn(['customize', 'logo']) or @props.logopath
    <img className='teamLogo' src={src} onClick={@props.onClickLogo}/>
    
  
  renderRemoveLogo: ->
    
    @renderButton 'custom-link-view remove', 'REMOVE', @props.onRemoveLogo
  
    
  renderUploadLogo: ->
    
    @renderButton 'custom-link-view primary', 'UPLOAD LOGO', @props.onClickLogo
    
    
  renderSaveButton: ->
    
    className = unless @props.canEdit then 'hidden' else ''
    className = kd.utils.curry 'custom-link-view primary fr', className
    @renderButton className, 'SAVE CHANGES', @props.onUpdate 
    
    
  renderDeleteButton: ->
    
    @renderButton '', 'DELETE TEAM', kd.noop
    
  
  renderTeamDomain: ->
    
    value = "#{Encoder.htmlDecode @props.team.get 'slug'}.koding.com" ? ''
    <input ref='teamDomain' type='text' name='url', className='kdinput text' disabled value={value} />
    

  renderTeamName: ->
    
    value = @props.teamName or Encoder.htmlDecode @props.team.get 'title' ? ''
    
    <input ref='teamName' type='text' name='title' className='kdinput text' value={value} onChange={@props.onTeamNameChanged}/>


  render: ->
    
    <div>
      <div className='HomeAppView--uploadLogo'>
        {@renderLogo()}
        <div className='uploadInputWrapper'>
          {@renderUploadLogo()}
          {@renderRemoveLogo()}
          {@renderUploadInput()}
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
          {@renderDeleteButton()}
          {@renderSaveButton()}
        </fieldset>
      </form>
    </div>