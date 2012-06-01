class JStatusUpdate extends JPost
  {secure} = bongo
  {Relationship} = jraphical

  {once} = require 'underscore'

  @share()

  @set
    sharedMethods     : JPost.sharedMethods
    schema            : jraphical.Message.schema
    relationships     : JPost.relationships

  @getActivityType =-> CStatusActivity

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback

class CStatusActivity extends CActivity

  @share()
  
  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       : JStatusUpdate
