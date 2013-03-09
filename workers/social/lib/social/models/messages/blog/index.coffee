JPost = require '../post'

module.exports = class JBlogPost extends JPost
  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'

  {once, extend} = require 'underscore'

  @share()

  schema = extend {}, JPost.schema, {
    html    : String
    checksum: String
  }

  @generateHTML=(content)->
    require('marked') content

  @generateChecksum=(content)->
    require('crypto')
      .createHash('sha1')
      .update(content)
      .digest 'hex'

  @set
    slugifyFrom       : 'title'
    sharedMethods     :
      static          : ['create','one','updateAllSlugs']
      instance        : [
        'reply','restComments','commentsByRange'
        'like','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify','fetchRelativeComments','checkIfLikedBefore'
      ]
    schema            : schema
    relationships     : JPost.relationships

  @getActivityType =-> require './blogpostactivity'

  @create = secure (client, data, callback)->
    blogPost  =
      meta        : data.meta
      title       : data.title
      body        : data.body
      group       : data.group
      html        : @generateHTML data.body
      checksum    : @generateChecksum data.body
    JPost.create.call @, client, blogPost, callback

  modify: secure (client, data, callback)->
    blogPost =
      meta        : data.meta
      title       : data.title
      body        : data.body
      html        : JBlogPost.generateHTML data.body
      checksum    : JBlogPost.generateChecksum data.body
    JPost::modify.call @, client, blogPost, callback

  reply: secure (client, comment, callback)->
    JComment = require '../comment'
    JPost::reply.call @, client, JComment, comment, callback