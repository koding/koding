{Attachment} = require 'jraphical'

class JCodeShareAttachment extends Attachment
  @setSchema
    description : String
    content     : String
    syntax      : String

JPost = require '../post'

module.exports = class JCodeShare extends JPost

  {secure} = require 'bongo'
  {extend} = require 'underscore'
  {permit} = require '../../group/permissionset'
  
  @trait __dirname, '../../../traits/grouprelated'

  {log} = console
  @share()

  @getActivityType =-> require './codeshareactivity'

  @getAuthorType =-> require '../../account'

  schema  = extend {}, JPost.schema, {
    CodeShareItems : Object
    CodeShareOptions : Object
  }

  @set
    sharedMethods : JPost.sharedMethods
    schema        : schema
    # TODO: copying and pasting this for now...  We need an abstract interface "commentable" or something like that)
    relationships : JPost.relationships

  @create = secure (client, data, callback)->
    codeShare=
      meta        : data.meta
      title       : data.title
      body        : data.body
      group       : data.group

      CodeShareItems : data.CodeShareItems or {}
      CodeShareOptions : data.CodeShareOptions or {}

    JPost.create.call @, client, codeShare, callback

  modify: secure (client, data, callback)->
    codeShare =
      meta        : data.meta
      title       : data.title
      body        : data.body

      CodeShareItems : data.CodeShareItems or {}
      CodeShareOptions : data.CodeShareOptions or {}

    JPost::modify.call @, client, codeShare, callback

  reply: permit 'reply to posts',
    success:(client, comment, callback)->
      JComment = require '../comment'
      JPost::reply.call @, client, JComment, comment, callback
