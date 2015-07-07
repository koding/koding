_ = require 'lodash'

defaultAccountOrigin = ->

  globals = require 'globals'

  return {
    id              : globals.userAccount._id
    _id             : globals.userAccount._id
    constructorName : 'JAccount'
  }


defaultAccount = ->
  profile  :
    firstName : 'a koding'
    lastName  : 'user'
    nickname  : '#'
  isExempt : no


defaultTrollAccount = -> _.assign {}, defaultAccount(), { isExempt: yes }


namelessAccount = (nickname) ->
  profile :
    nickname  : 'foouser'
    firstName : ''
    lastName  : ''


getGravatarUri = (account, size) ->

  {hash} = account.profile

  # make sure we are fetching an image with a non-decimal size.
  size = Math.round size

  defaultUri = """
    https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.#{size}.png
  """

  {protocol} = global.location

  return "#{protocol}//gravatar.com/avatar/#{hash}?size=#{size}&d=#{defaultUri}&r=g"


module.exports = {
  defaultAccountOrigin
  defaultAccount
  defaultTrollAccount
  namelessAccount
  getGravatarUri
}


