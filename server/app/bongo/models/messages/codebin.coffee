class JCodeBinAttachment extends jraphical.Attachment
  @setSchema
    description : String
    content     : String
    syntax      : String

class JCodeBin extends JPost

  {secure} = require 'bongo'

  @share()

  @getActivityType =-> CCodeBinActivity

  @getAuthorType =-> JAccount

  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    # TODO: copying and pasting this for now...  We need an abstract interface "commentable" or something like that)
    relationships : JPost.relationships

  @create = secure (client, data, callback)->
    codeBin=
      meta        : data.meta
      title       : data.title
      body        : data.body
      attachments : [{
        type      : 'JCodeBinAttachment'
        content   : data.codeHTML
        syntax    : 'html'
      },
      {
        type      : 'JCodeBinAttachment'
        content   : data.codeCSS
        syntax    : 'css'
      },
      {
        type      : 'JCodeBinAttachment'
        content   : data.codeJS
        syntax    : 'javascript'
      }]
    JPost.create.call @, client, codeBin, callback

  modify: secure (client, data, callback)->
    codeBin =
      meta        : data.meta
      title       : data.title
      body        : data.body
      attachments : [{
        type      : 'JCodeBinAttachment'
        content   : data.codeHTML
        syntax    : 'html'
      },
      {
        type      : 'JCodeBinAttachment'
        content   : data.codeCSS
        syntax    : 'css'
      },
      {
        type      : 'JCodeBinAttachment'
        content   : data.codeJS
        syntax    : 'javascript'
      }]

    JPost::modify.call @, client, codeBin, callback

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback

class CCodeBinActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JCodeBin
        as          : 'content'
