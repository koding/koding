kd = require 'kd'
React = require 'app/react'
CredentialListItem = require './credentiallistitem'

HomeCredentialFlux = require 'home/account/credentials/flux'

module.exports = class CloudCredentialsView extends React.Component

  setItemClickEvent: (items, id) ->
    return []  unless items
    for i in [0..items.length-1]
      items[i].onClick = HomeCredentialFlux.actions["onClickCredential#{items[i].title}"].bind(this, id)

    return items

  render: ->

    { sharedWithMeCredentials
      mySharedCredentials
      privateCloudCredentials
      cloudCredentialsOptions } = @props


    <div className='cloud-credential-view'>
      {
        null if mySharedCredentials.size
        mySharedCredentials.map (cred) =>
          items = cloudCredentialsOptions.get cred.get '_id'
          items = @setItemClickEvent items, cred.get '_id'
          <CredentialListItem key={cred.get '_id'} credential={cred} shared={yes} items={items}/>
      }
      {
        null if sharedWithMeCredentials.size
        sharedWithMeCredentials.map (cred) =>
          items = cloudCredentialsOptions.get cred.get '_id'
          items = @setItemClickEvent items, cred.get '_id'
          <CredentialListItem key={cred.get '_id'} credential={cred} shared={yes} items={items}/>
      }
      {
        null if privateCloudCredentials.size
        privateCloudCredentials.map (cred) =>
          items = cloudCredentialsOptions.get cred.get '_id'
          items = @setItemClickEvent items, cred.get '_id'
          <CredentialListItem key={cred.get '_id'} credential={cred} shared={no} items={items}/>
      }
    </div>

