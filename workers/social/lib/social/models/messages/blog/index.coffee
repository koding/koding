JPost = require '../post'

module.exports = class JBlogPost extends JPost

  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'
  {permit} = require '../../group/permissionset'
  {once, extend} = require 'underscore'

  @trait __dirname, '../../../traits/grouprelated'

  @share()

  schema = extend {}, JPost.schema, {
    html    : String
    checksum: String
  }

  @generateHTML=(content)->
    options =
      gfm : yes
      sanitize : yes
      highlight : (code, lang)->
        hljs = require('highlight.js')
        try
          hljs.highlight(lang, code).value
        catch e
          try
            hljs.highlightAuto(code).value
          catch _e
            code
      breaks : yes
      langPrefix : 'lang-'
    marked = require('marked')
    marked.setOptions options
    marked content

  @generateChecksum=(content)->
    require('crypto')
      .createHash('sha1')
      .update(content)
      .digest 'hex'

  @set
    slugifyFrom       : 'title'
    sharedMethods     :
      static          : ['create','one','updateAllSlugs','some']
      instance        : [
        'reply','restComments','commentsByRange'
        'like','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify','fetchRelativeComments','checkIfLikedBefore'
      ]
    sharedEvents      :
      instance        : [
        { name: 'TagsChanged' }
        { name: 'ReplyIsAdded' }
        { name: 'LikeIsAdded' }
        { name: 'updateInstance' }
      ]
      static          : []
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

  reply: permit 'reply to posts',
    success:(client, comment, callback)->
      JComment = require '../comment'
      JPost::reply.call @, client, JComment, comment, callback