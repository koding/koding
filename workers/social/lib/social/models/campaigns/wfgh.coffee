KodingError = require '../../error'
JCampaign  = require './campaign'
{ Model }  = require 'bongo'

module.exports = class JWFGH extends Model

  { signature, secure } = require 'bongo'
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
        set       : (value) -> value.toLowerCase()
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

    return callback new KodingError 'No username received!'  unless username

    JCampaign.get 'WFGH', (err, campaign) ->

      if err or not campaign or not campaign.content.active

        return callback new KodingError 'expired'

      JWFGH.one { username }, (err, data) ->

        return callback err  if err

        return callback new KodingError 'Already applied'  if data

        application = new JWFGH { username }

        application.save (err) ->

          return callback err if err

          JWFGH.getStats account, callback


  @leave = (account, callback) -> callback new KodingError 'n/a'


  getUserStats = (username, callback) ->

    JWFGH.one { username }, (err, applied) ->

      return callback err  if err

      isApplicant = applied?
      isApproved  = applied?.approved
      isWinner    = applied?.winner

      callback null, { isApplicant, isApproved, isWinner }


  @getStats = (account, callback) ->

    JCampaign.get 'WFGH', (err, _campaign) ->

      if err or not _campaign or not _campaign.content.active

        return callback new KodingError 'expired'

      kallback = (err, userStats) ->
        { isApplicant, isApproved, isWinner } = userStats

        campaign           = _campaign.content
        totalApplicants    = campaign.totalApplicants or 0
        approvedApplicants = campaign.approvedApplicants or 0

        res = { approvedApplicants, totalApplicants, isApplicant, isApproved, isWinner, campaign }

        callback err, res

      if username = account?.profile?.nickname
      then getUserStats username, kallback
      else kallback null, {
        isWinner      : no
        isApproved    : no
        isApplication : no
      }
