React                = require 'kd-react'
ProfileTextContainer = require 'app/components/profile/profiletextcontainer'

module.exports = makeProfileText = (origin) ->

  # if it's immutable turn it to regular object.
  origin = origin.toJS()  if typeof origin.toJS is 'function'
  origin.id or= origin._id

  return \
    <ProfileTextContainer key={origin.id} origin={origin} />
