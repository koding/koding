JPost = require '../post'

module.exports = class JStatusUpdate extends JPost
  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'

  {once, extend} = require 'underscore'

  @share()

  schema = extend {}, JPost.schema, {
    link :
      link_cache              : Array
      link_url                : String
      link_embed              : Object
      link_embed_hidden_items : Array
      link_embed_image_index  : Number
  }

  @set
    sharedMethods     :
      static          : ['create','one','fetchDataFromEmbedly']
      instance        : [
        'reply','restComments','commentsByRange'
        'like','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify','fetchRelativeComments','checkIfLikedBefore'
      ]
    schema            : schema
    relationships     : JPost.relationships

  @getActivityType =-> require './statusactivity'

  @fetchDataFromEmbedly = (url, options, callback)->

    {log}      = require 'console'
    util       = require "util"

    {Api}    = require "embedly"

    embedly = new Api
      user_agent : 'Mozilla/5.0 (compatible; koding/1.0; arvid@koding.com)'
      key        : "e8d8b766e2864a129f9e53460d520115"

    embedOptions = extend {}, options, {url:url}

    embedly.preview(embedOptions).on "complete", (data)->
      callback JSON.stringify data
    .on "error", (data)->
      callback JSON.stringify data
    .start()

  @create = secure (client, data, callback)->
    statusUpdate  =
      meta        : data.meta
      title       : data.title
      body        : data.body

    if data.link_url and data.link_embed
      statusUpdate.link         =
        link_cache              : data.link_cache
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
        link_cache              : data.link_cache
        link_url                : data.link_url
        link_embed              : data.link_embed
        link_embed_hidden_items : data.link_embed_hidden_items
        link_embed_image_index  : data.link_embed_image_index

    JPost::modify.call @, client, statusUpdate, callback

  reply: secure (client, comment, callback)->
    JComment = require '../comment'
    JPost::reply.call @, client, JComment, comment, callback