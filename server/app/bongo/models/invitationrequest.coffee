class JInvitationRequest extends bongo.Model
<<<<<<< HEAD
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
=======

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

  @create =({email}, callback)->
>>>>>>> 06e2457ff87902c39eed6521079b9ad883c7cc5b
    invite = new @ {email}
    invite.save (err)->
      if err
        callback err
      else
        callback null, email