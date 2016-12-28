whoami = require 'app/util/whoami'
immutable = require 'immutable'

CredentialsStore     = ['CredentialsStore']
CredentialUsersStore = ['CredentialUsersStore']

customCredentials = [
  CredentialsStore
  (credentials) -> credentials.filter (c) -> c.get('provider') is 'custom'
]


cloudCredentials = [
  CredentialsStore
  customCredentials
  (credentials, customCredentials) ->
    credentials.filter (c) -> not customCredentials.get c.get '_id'
]


cloudCredentialsOptions = [
  cloudCredentials
  (credentials) ->
    credentials.map (c) ->
      options = []
      options.push { title: 'Preview', key: 'preview', onClick: -> }
      options.push { title: 'Remove', key: 'remove', onClick: -> }
      options.push if c.get('accessLevel') isnt 'private' and c.get('originId') is whoami()._id
      then { title: 'Unshare', key: 'unshare', onClick: -> }
      else { title: 'Share', key: 'share', onClick: -> }

      return options
]


sharedCredentials = [
  CredentialsStore
  customCredentials
  (credentials, customCredentials) -> credentials.filter (c) ->
    c.get('accessLevel') isnt 'private' and not customCredentials.get c.get '_id'
]


mySharedCredentials = [
  sharedCredentials
  (credentials) -> credentials.filter (c) -> c.get('originId') is whoami()._id
]


sharedWithMeCredentials = [
  sharedCredentials
  (credentials) -> credentials.filter (c) -> c.get('originId') isnt whoami()._id
]


privateCloudCredentials = [
  CredentialsStore
  (credentials) -> credentials.filter (c) ->
    c.get('accessLevel') is 'private' and c.get('provider') isnt 'custom'
]


groupsInCredentialUsers = [
  CredentialUsersStore
  (object) -> object.filter (o) -> o.get('constructorName') is 'JGroup'
]

module.exports = {
  credentials: CredentialsStore
  customCredentials
  sharedCredentials
  privateCloudCredentials
  mySharedCredentials
  sharedWithMeCredentials
  credentialUsers: CredentialUsersStore
  cloudCredentialsOptions
}
