JPost = require '../post'

module.exports = class JLink extends JPost
  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'

  {once,extend} = require 'underscore'
  {log} = console

  @share()

  schema = extend {}, JPost.schema, {
    link_url   : String
    link_embed : Object
    link_embed_hidden_items : Array
  }

  @set
    sharedMethods     : JPost.sharedMethods
    schema            : schema
    relationships     : JPost.relationships

  @getActivityType =-> require './linkactivity'

  @create = secure (client, data, callback)->
    link =
      title                   : data.title
      body                    : data.body
      link_url                : data.link_url
      link_embed              : data.link_embed
      link_embed_hidden_items : data.link_embed_hidden_items
      meta                    : data.meta
    JPost.create.call @, client, link, callback

  modify: secure (client, data, callback)->
    link =
      title       : data.title
      body        : data.body
      link_url    : data.link_url
      link_embed  : data.link_embed
      link_embed_hidden_items : data.link_embed_hidden_items
      meta        : data.meta
    JPost::modify.call @, client, link, callback

  reply: secure (client, comment, callback)->
    JComment = require '../comment'
    JPost::reply.call @, client, JComment, comment, callback