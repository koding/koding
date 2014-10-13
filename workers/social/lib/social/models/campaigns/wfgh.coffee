{Model} = require 'bongo'

module.exports = class JWFGH extends Model

  CAP       = 50000
  PRIZE     = 10000
  DEADLINE  = new Date 1418626800000 # Mon, 15 Dec 2014 00:00:00 PDT

  {signature, secure} = require 'bongo'
  @share()

  @set
    indexes       :
      username    : 'unique'
      approved    : 'unique'
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

    username = account.profile.nickname

    JWFGH.one {username}, (err, data)->

      return callback err  if err

      return callback message : 'Already applied'  if data

      application = new JWFGH {username}

      application.save (err)->
        return callback err if err
        JWFGH.getStats account, callback



  @leave = (account, callback) ->

    callback null, 'n/a'


  @getStats = (account, callback) ->

    username = account?.profile?.nickname

    unless username
      callback null,
        cap                : CAP
        prize              : PRIZE
        deadline           : DEADLINE
        totalApplicants    : 0
        approvedApplicants : 0
        isApplicant        : no

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
            cap      : CAP
            prize    : PRIZE
            deadline : DEADLINE
            totalApplicants, approvedApplicants
            isApplicant, isApproved, isWinner
          }