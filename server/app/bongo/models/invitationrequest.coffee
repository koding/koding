class JInvitationRequest extends bongo.Model
  @share()
  
  @set
    schema          :
      email         :
        type        : String
        email       : yes
      sharedMethods :
        static      : ['create']
      requestedAt   :
        type        : Date
        default     : -> new Date
  
  @create =(email, callback)->
    invite = new @ {email}
    invite.save (err)->
      if err
        callback err
      else
        callback null, email