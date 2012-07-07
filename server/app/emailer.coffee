Emailer = postmark
  
class JEmailNotification extends bongo.Model
  
  @setSchema
    email     : String
    receiver  : Object
    event     : String
    contents  : Object
    
  constructor:(email, receiver, event, contents)->
    super {email, receiver, event, contents}