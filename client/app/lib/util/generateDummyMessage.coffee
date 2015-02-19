whoami = require './whoami'
extend = require('util')._extend

# Generates a fake SocialMessage object
module.exports = (body) ->

  now       = new Date
  isoNow    = now.toISOString()

  account = extend whoami(),
    constructorName: 'JAccount'

  fakeObject         =
    isFake            : yes
    on                : -> this
    watch             : -> this
    body              : body
    account           : account
    createdAt         : isoNow
    updatedAt         : isoNow
    replies           : []
    repliesCount      : 0
    interactions      :
      like            :
        isInteracted  : no
        actorsCount   : 0
        actorsPreview : []
 
