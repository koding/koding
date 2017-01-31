kd = require 'kd'
View = require './view'
React = require 'app/react'
KDReactorMixin = require 'app/flux/base/reactormixin'
HomeCredentialFlux = require 'home/account/credentials/flux'


module.exports = class CredentialsListContainer extends React.Component

  getDataBindings: ->
    return {
      credentials: HomeCredentialFlux.getters.credentials
      customCredentials: HomeCredentialFlux.getters.customCredentials
      sharedCredentials: HomeCredentialFlux.getters.sharedCredentials
      sharedWithMeCredentials: HomeCredentialFlux.getters.sharedWithMeCredentials
      mySharedCredentials: HomeCredentialFlux.getters.mySharedCredentials
      privateCloudCredentials: HomeCredentialFlux.getters.privateCloudCredentials
      credentialUsers: HomeCredentialFlux.getters.credentialUsers
      cloudCredentialsOptions: HomeCredentialFlux.getters.cloudCredentialsOptions
    }

  render: ->

    { credentials
      customCredentials
      sharedCredentials
      mySharedCredentials
      sharedWithMeCredentials
      privateCloudCredentials
      credentialUsers
      cloudCredentialsOptions } = @state

    <View
      credentials={credentials}
      customCredentials={customCredentials}
      sharedCredentials={sharedCredentials}
      sharedWithMeCredentials={sharedWithMeCredentials}
      privateCloudCredentials={privateCloudCredentials}
      mySharedCredentials={mySharedCredentials}
      cloudCredentialsOptions={cloudCredentialsOptions} />

CredentialsListContainer.include [KDReactorMixin]
