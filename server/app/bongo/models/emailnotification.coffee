class JEmailNotification extends bongo.Model
  
  @setSchema
    email     : String
    receiver  : Object
    event     : String
    contents  : Object
    status    :
      type    : String
      default : 'queued'
      enum    : ['Invalid status',['queued', 'attempted']]
    
  constructor:(email, receiver, event, contents)->
    super {email, receiver, event, contents}