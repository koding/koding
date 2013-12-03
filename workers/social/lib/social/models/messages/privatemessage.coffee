
JPost       = require './post'
JComment    = require './comment'
KodingError = require '../../error'

module.exports = class JPrivateMessage extends JPost

  {ObjectRef, secure, race} = require 'bongo'

  jraphical = require 'jraphical'
  {unique}  = require 'underscore'

  @trait __dirname, '../../traits/grouprelated'

  @share()

  @set
    sharedMethods :
      static      : ['create','on']
      instance    : [
        'reply','restComments','commentsByRange','like',
        'fetchLikedByes','disown','mark',
        'unmark','fetchRelativeComments'
      ]
    sharedEvents  :
      static      : []
      instance    : ['updateInstance']
    schema        : jraphical.Message.schema
    # TODO: copying and pasting this for now...
    # We need an abstract interface "commentable" or something like that)
    relationships : JPost.relationships

  constructor:->
    super
    @on 'ReplyIsAdded', ({replier})=>
      @informParticipants replier

  reply: secure (client, comment, callback)->
    JComment = require './comment'
    JPost::reply.call @, client, JComment, comment, callback

  disown: secure ({connection}, callback)->
    {delegate} = connection
    delegate.removePrivateMessage @, {as: $in: ['sender', 'recipient']}, \
    callback

  informParticipants:(replier)->
    jraphical.Relationship.all
      targetName : 'JPrivateMessage'
      targetId   : @getId()
    , (err, rels)=>
      return warn err  if err
      rels.forEach (rel)=>
        rel.update $set: timestamp: new Date, (err)->
          console.warn "Relationship date update failed:", err  if err
        unless rel.sourceId.equals replier.id
          @unflag 'read', rel.sourceId, ['recipient', 'sender']

  @create = do ->
    # a helper for sending to mulitple recipients.
    dispatchMessages =(sender, recipients, pm, callback)->
      deliver = race (i, recipient, pm, fin)->
        recipient.addPrivateMessage pm, {as:'recipient'}, (err)->
          if err
            fin err
          else

            recipient.emit 'PrivateMessageSent',
              origin        : recipient
              subject       : ObjectRef(pm).data
              actorType     : 'sender'
              actionType    : 'newMessage'
              sender        : ObjectRef(sender).data

            fin()
      , callback
      deliver recipient, pm for recipient in recipients

    secure (client, data, callback = (->)) ->
      {delegate} = client.connection

      JAccount = require '../account'

      if delegate.type is 'unregistered'
        callback new KodingError 'Access denied'
        return no

      {to, subject, body} = data
      if 'string' is typeof to
        # accept virtaully any non-wordchar delimiters for now.
        to = to.replace(/[^\w\s-]/g, ' ').replace(/\s+/g, ' ').split(' ')
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
