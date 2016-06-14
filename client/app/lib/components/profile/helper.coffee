_ = require 'lodash'
proxifyUrl = require 'app/util/proxifyUrl'
regexps = require 'app/util/regexps'


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

  { hash } = account.profile

  # make sure we are fetching an image with a non-decimal size.
  size = Math.round size

  defaultUri = """
    https://koding-cdn.s3.amazonaws.com/new-avatars/default.avatar.#{size}.png
  """

  { protocol } = global.location

  return "#{protocol}//gravatar.com/avatar/#{hash}?size=#{size}&d=#{defaultUri}&r=g"


getAvatarUri = (account, width, height, dpr) ->

  { profile } = account
  if profile.avatar?.match regexps.webProtocolRegExp
    width  = width * dpr
    height = height * dpr
    return proxifyUrl profile.avatar, { crop: yes, width, height }

   return getGravatarUri account, width * dpr


module.exports = {
  defaultAccountOrigin
  defaultAccount
  defaultTrollAccount
  namelessAccount
  getGravatarUri
  getAvatarUri
}
