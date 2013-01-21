{Model} = require 'bongo'

module.exports = class JInvitationRequest extends Model

  {daisy}   = require 'bongo'

  csvParser = require 'csv'

  @share()

  @set
    indexes           :
      email           : 'unique'
    sharedMethods     :
      static          : ['create'] #,'__importKodingenUsers']
    schema            :
      email           :
        type          : String
        email         : yes
      kodingen        :
        isMember      : Boolean
        username      : String
        registeredAt  : Date
      requestedAt     :
        type          : Date
        default       : -> new Date

  @create =({email}, callback)->
    invite = new @ {email}
    invite.save (err)->
      console.log "->",arguments
      if err
        callback err
      else
        callback null, email

  @__importKodingenUsers =do->
    pathToKodingenCSV = 'kodingen/wp_users.csv'
    (callback)->
      queue = []
      errors = []
      eterations = 0
      csv = csvParser().fromPath pathToKodingenCSV, escape: '\\'
      csv.on 'data', (datum)->
        if datum[0] isnt 'ID'
          deleted = datum.pop()+''
          spam    = datum.pop()+''
          if '1' in [deleted, spam]
            reason = {deleted, spam}
            csv.emit 'error', "this datum is invalid because #{JSON.stringify reason}"
          else
            queue.push ->
              [__id, username, __hashedPassword, __nicename, email, __url, registeredAt] = datum
              inviteRequest = new JInvitationRequest {
                email
                kodingen    : {
                  isMember  : yes
                  username
                  registeredAt: Date.parse registeredAt
                }
              }
              inviteRequest.save queue.next.bind queue
      csv.on 'end', (count)->
        callback "Finished parsing #{count} records, of which #{queue.length} were valid."
        daisy queue
      csv.on 'error', (err)-> errors.push err