jraphical = require 'jraphical'

JPost = require '../post'

class JCodeAttachment extends jraphical.Attachment
  @setSchema
    description : String
    content     : String
    syntax      : String


module.exports = class JCodeSnip extends JPost

  {secure} = require 'bongo'
  {extend} = require 'underscore'

  @share()

  @getActivityType =-> require './codesnipactivity'

  @getAuthorType =-> require '../../account'

  schema = extend {}, JPost.schema, {
    attachments   : [JCodeAttachment]
  }

  @set
    indexes       :
      slug        : 'unique'
    sharedMethods : JPost.sharedMethods
    schema        : schema
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
      meta        : data.meta
    JPost::modify.call @, client, codeSnip, callback

  reply: secure (client, comment, callback)->
    JComment = require '../comment'
    JPost::reply.call @, client, JComment, comment, callback
