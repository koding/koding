class JInvitationRequest extends bongo.Model

  @share()
  
  @set
    indexes       :
      email       : 'unique'
    sharedMethods :
      static      : ['create']
    schema        :
      email       :
        type      : String
        email     : yes
      requestedAt :
        type      : Date
        default   : -> new Date
      sent        : Boolean

  @create =({email}, callback)->    
    invite = new @ {email}
    invite.save (err)->
      if err
        callback err
      else
        callback null, email

  createInviteCode: (email)->
    code = crypto
      .createHmac('sha1', 'kodingsecret')
      .update(email)
      .digest('hex')
    return code

  getInvitedBy: (username,callback)->
    JAccount.one {'profile.nickname': username}, (err, user)->
      if err then callback err
      else callback null,user

  send :({email},callback)->

    inviter = @getInvitedBy 'devrim',(err,user)->

    invite = new JInvitation
      code          : @createInviteCode email
      inviteeEmail  : email
      maxUses       : 1
      origin        : ObjectRef(user)
      type          : 'launchrock'
    
    invite.save (err)-> 