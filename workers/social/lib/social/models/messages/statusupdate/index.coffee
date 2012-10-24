JPost = require '../post'

module.exports = class JStatusUpdate extends JPost
  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'

  {once, extend} = require 'underscore'

  @share()

  schema = extend {}, JPost.schema, {
    link :
      link_url                : String
      link_embed              : Object
      link_embed_hidden_items : Array
      link_embed_image_index  : Number
  }

  @set
    sharedMethods     : JPost.sharedMethods
    schema            : schema
    relationships     : JPost.relationships

  @getActivityType =-> require './statusactivity'


  @create = secure (client, data, callback)->
    statusUpdate  =
      meta        : data.meta
      title       : data.title
      body        : data.body

    if data.link_url and data.link_embed
      statusUpdate.link         =
        link_url                : data.link_url
        link_embed              : data.link_embed
        link_embed_hidden_items : data.link_embed_hidden_items
        link_embed_image_index  : data.link_embed_image_index

    JPost.create.call @, client, statusUpdate, callback

  modify: secure (client, data, callback)->
    statusUpdate =
      meta        : data.meta
      title       : data.title
      body        : data.body

    if data.link_url and data.link_embed
      statusUpdate.link         =
        link_url                : data.link_url
        link_embed              : data.link_embed
        link_embed_hidden_items : data.link_embed_hidden_items
        link_embed_image_index  : data.link_embed_image_index

    JPost::modify.call @, client, statusUpdate, callback

  reply: secure (client, comment, callback)->
    JComment = require '../comment'
    JPost::reply.call @, client, JComment, comment, callback