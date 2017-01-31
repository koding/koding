kd = require 'kd'
React = require 'app/react'
CloudCredentialsView = require './cloudcredentialsview'

module.exports = class CredentialListView extends React.Component


  render: ->

    <div className='credential-list-view'>
      <CloudCredentialsView
        sharedWithMeCredentials={@props.sharedWithMeCredentials}
        sharedCredentials={@props.sharedCredentials}
        privateCloudCredentials={@props.privateCloudCredentials}
        mySharedCredentials={@props.mySharedCredentials}
        cloudCredentialsOptions={@props.cloudCredentialsOptions} />
    </div>



