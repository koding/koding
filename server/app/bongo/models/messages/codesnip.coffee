class JCodeAttachment extends jraphical.Attachment
  @setSchema
    description : String
    content     : String
    syntax      : String

class JCodeSnip extends JPost

  {secure} = require 'bongo'
  
  @share()
  
  @getActivityType =-> CCodeSnipActivity
  
  @getAuthorType =-> JAccount
  
  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    # TODO: copying and pasting this for now...  We need an abstract interface "commentable" or something like that)
    relationships : JPost.relationships
  
  @create = secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      attachments : [{
        type      : 'JCodeAttachment'
        content   : data.code
        syntax    : data.syntax
      }]
      meta        : data.meta
    JPost.create.call @, client, codeSnip, callback
  
  modify: secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      attachments : [{
        type      : 'JCodeAttachment'
        content   : data.code
        syntax    : data.syntax
      }]
    JPost::modify.call @, client, codeSnip, callback
  
  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback

class CCodeSnipActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        type        : JCodeSnip
        as          : 'content'
      
