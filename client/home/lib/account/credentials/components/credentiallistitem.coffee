kd = require 'kd'
React = require 'app/react'
ButtonWithMenu = require 'app/components/buttonwithmenu'
AutoCompleteCredentialShare = require './autocompletecredentialshare'

module.exports = class CredentialListItem extends React.Component

  render: ->
    custom = @props.credential.get('provider') is 'custom'

    <div className='credentials-list-item'>
      {if custom
        <CustomCredential {...@props} />
      else
        <div className='cloud-credential-wrapper'>
          <CloudCredential {...@props} />
          <AutoCompleteCredentialShare />
        </div>
      }
    </div>


CustomCredential = (props) ->

  return <div className='credentials-list-item-custom'>NAMBEr</div>


CloudCredential = (props) ->
  shared = props.shared

  <div className='credentials-list-item-cloud'>
    <ProviderIcon provider={props.credential.get 'provider'} />
    <Title title={props.credential.get 'title'} />
    <SharedTag shared={shared}/>
    <CredOwner nickname={'hakan'} />
    <div className='dropdown'>
      {<ButtonWithMenu menuClassName='menu-class' items={props.items} isMenuOpen={no} />}
    </div>
  </div>


SharedTag = ({ shared }) ->

  return null  unless shared
  <div className='shared-tag'>
    <div className='tag'>Shared</div>
  </div>


CredOwner = ({ nickname }) ->

  <span className='credential-owner'>
    By @{nickname}
  </span>


Title = ({ title }) ->

  <div className='title'>
    {title}
  </div>


ProviderIcon = ({ provider }) ->

  <div className = 'providericon-wrapper' style={{height: 'auto', width: '32px'}}>
    <div className={provider} style={{width: '100%'}}></div>
  </div>
