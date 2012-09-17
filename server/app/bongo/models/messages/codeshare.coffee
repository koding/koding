class JCodeShareAttachment extends jraphical.Attachment
  @setSchema
    description : String
    content     : String
    syntax      : String

class JCodeShare extends JPost

  {secure} = require 'bongo'

  @share()

  @getActivityType =-> CCodeShareActivity

  @getAuthorType =-> JAccount

  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    # TODO: copying and pasting this for now...  We need an abstract interface "commentable" or something like that)
    relationships : JPost.relationships

  @create = secure (client, data, callback)->
    codeShare=
      meta        : data.meta
      title       : data.title
      body        : data.body
      attachments : [{
        type      : 'JCodeShareAttachment'
        content   : data.codeHTML
        syntax    : 'html'
      },
      {
        type      : 'JCodeShareAttachment'
        content   : data.codeCSS
        syntax    : 'css'
      },
      {
        type      : 'JCodeShareAttachment'
        content   : data.codeJS
        syntax    : 'javascript'
      }]
    JPost.create.call @, client, codeShare, callback

  modify: secure (client, data, callback)->
    codeShare =
      meta        : data.meta
      title       : data.title
      body        : data.body
      attachments : [{
        type      : 'JCodeShareAttachment'
        content   : data.codeHTML
        syntax    : 'html'
      },
      {
        type      : 'JCodeShareAttachment'
        content   : data.codeCSS
        syntax    : 'css'
      },
      {
        type      : 'JCodeShareAttachment'
        content   : data.codeJS
        syntax    : 'javascript'
      }]

    JPost::modify.call @, client, codeShare, callback

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback

class CCodeShareActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JCodeShare
        as          : 'content'
