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


  getUserStats = (username, callback) ->

    JWFGH.one {username}, (err, applied)->

      return callback err  if err

      isApplicant = applied?
      isApproved  = applied?.approved
      isWinner    = applied?.winner

      callback null, {isApplicant, isApproved, isWinner}


  @getStats = (account, callback) ->

    JCampaign.get 'WFGH', (err, campaign) ->

      if err or not campaign or not campaign.content.active

        return callback message : 'expired'

      JWFGH.count {}, (err, totalApplicants)->

        return callback err  if err

        JWFGH.count approved : yes, (err, realApprovedApplicants)->

          return callback err  if err

          kallback = (err, userStats) ->
            {isApplicant, isApproved, isWinner} = userStats

            approvedApplicants = campaign.content.approvedApplicants or 0
            aac                = realApprovedApplicants

            callback err, {
              totalApplicants, approvedApplicants, aac
              isApplicant, isApproved, isWinner
              campaign: campaign.content
            }

          if username = account?.profile?.nickname
          then getUserStats username, kallback
          else kallback null, {
            isWinner      : no
            isApproved    : no
            isApplication : no
          }
