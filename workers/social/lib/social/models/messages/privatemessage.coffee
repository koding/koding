
JPost       = require './post'
JComment    = require './comment'
KodingError = require '../../error'

module.exports = class JPrivateMessage extends JPost

  {ObjectRef, secure, race} = require 'bongo'

  jraphical = require 'jraphical'

  @share()

  @set
    sharedMethods     :
      static          : ['create','on']
      instance        : [
        'reply','restComments','commentsByRange','like',
        'fetchLikedByes','disown','collectParticipants','mark',
        'unmark','fetchRelativeComments'
      ]
    schema        : jraphical.Message.schema
    # TODO: copying and pasting this for now...  We need an abstract interface "commentable" or something like that)
    relationships : JPost.relationships

  reply: secure (client, comment, callback)->
    JComment = require './comment'
    JPost::reply.call @, client, JComment, comment, callback

  disown: secure ({connection}, callback)->
    {delegate} = connection
    delegate.removePrivateMessage @, {as: $in: ['sender', 'recipient']}, callback

  collectParticipants: secure ({connection}, callback)->
    {delegate} = connection
    register = new Register # a register per message...
    jraphical.Relationship.all targetName: 'JPrivateMessage', targetId: @getId(), sourceId: $ne: delegate.getId(), (err, rels)=>
      if err
        callback err
      else
        @participants = (rel for rel in rels when register.sign rel.sourceId) # only include unique participants.
        callback null,@

  @create = do ->
    # a helper for sending to mulitple recipients.
    dispatchMessages =(sender, recipients, pm, callback)->
      deliver = race (i, recipient, pm, fin)->
        recipient.addPrivateMessage pm, (err)->
          if err
            fin err
          else
            recipient.sendNotification 'NewPrivateMessageHasArrived',
              actorType   : 'sender'
              actionType  : 'newMessage'
              sender      : ObjectRef(sender).data
              subject     : ObjectRef(pm).data
            fin()
            # jraphical.Channel.fetchPrivateChannelById recipient.getId(), (err, channel)->
            #   channel.publish sender, pm
      , callback
      deliver recipient, pm for recipient in recipients

    secure (client, data, callback)->
      {delegate} = client.connection

      JAccount = require '../account'

      unless delegate instanceof JAccount
        callback new KodingError 'Access denied.'
        return no

      {to, subject, body} = data
      if 'string' is typeof to
        to = to.replace(/[^\w\s]/g, ' ').replace(/\s+/g, ' ').split(' ') # accept virtaully any non-wordchar delimiters for now.
      JAccount.all 'profile.nickname': $in: to, (err, recipients)->
        if err
          callback err
        else unless recipients?
          callback new Error "couldn't find any of these usernames: #{to}"
        else
          pm = new JPrivateMessage {
            subject
            body
          }
          pm.sign(delegate)
          pm.save (err)->
            if err
              callback err
            else
              dispatchMessages delegate, recipients, pm, (err)->
                if err
                  callback err
                else
                  delegate.addPrivateMessage pm, 'sender', (err)->
                    if err
                      callback err
                    else
                      callback null, pm
#                      unless delegate.profile.nickname in to
#                        jraphical.Channel.fetchPrivateChannelById delegate.getId(), (err, channel)->
#                          channel.publish delegate, pm
