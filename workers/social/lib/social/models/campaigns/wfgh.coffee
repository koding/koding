JCampaign = require './campaign'
{Model}  = require 'bongo'

module.exports = class JWFGH extends Model

  {signature, secure} = require 'bongo'
  @share()

  @set
    indexes       :
      username    : 'unique'
      approved    : 'unique'
    sharedMethods :
      static      :
        create    : (signature Object, Function)
    schema        :
      username    :
        type      : String
        validate  : require('./../name').validateName
        set       : (value)-> value.toLowerCase()
      approved    :
        type      : Boolean
        default   : -> no
      winner      :
        type      : Boolean
        default   : -> no
      createdAt   :
        type      : Date
        default   : -> new Date


  @apply = (account, callback) ->

    username = account?.profile?.nickname

    return callback message : 'No username received!'  unless username

    JCampaign.get 'WFGH', (err, campaign) ->

      if err or not campaign or not campaign.content.active

        return callback message : 'expired'

      JWFGH.one {username}, (err, data)->

        return callback err  if err

        return callback message : 'Already applied'  if data

        application = new JWFGH {username}

        application.save (err)->

          return callback err if err

          JWFGH.getStats account, callback


  @leave = (account, callback) ->

    callback message : 'n/a'


  @getStats = (account, callback) ->

    JCampaign.get 'WFGH', (err, campaign) ->

      if err or not campaign or not campaign.content.active

        return callback message : 'expired'

      username = account?.profile?.nickname

      {cap, prize, deadline} = campaign

      cap      ?= 50000
      prize    ?= 10000
      deadline ?= new Date 1418626800000 # Mon, 15 Dec 2014 00:00:00 PDT

      unless username

        callback null, {
          totalApplicants    : 0
          approvedApplicants : 0
          isApplicant        : no
          deadline
          prize
          cap
        }

      JWFGH.one {username}, (err, applied)->

        return callback err  if err

        isApplicant = applied?
        isApproved  = applied?.approved
        isWinner    = applied?.winner

        JWFGH.count {}, (err, totalApplicants)->

          return callback err  if err

          JWFGH.count approved : yes, (err, approvedApplicants)->

            return callback err  if err

            callback err, {
              cap, prize, deadline
              totalApplicants, approvedApplicants
              isApplicant, isApproved, isWinner
            }