JPost = require '../post'

module.exports = class JBlogPost extends JPost

  {secure}       = require 'bongo'
  {Relationship} = require 'jraphical'
  {permit}       = require '../../group/permissionset'
  {once}         = require 'underscore'
  {sanitize}     = require 'validator'

  @trait __dirname, '../../../traits/grouprelated'

  @share()

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
        { name: 'RemovedFromCollection' }
        { name: 'PostIsDeleted' }
      ]
      static          : [
        { name: 'updateInstance' }
        { name: 'RemovedFromCollection' }
      ]
    schema            : JPost.schema
    relationships     : JPost.relationships

  @getActivityType =-> require './blogpostactivity'

  @create = secure (client, data, callback)->
    JMarkdownDoc = require '../../markdowndoc'
    blogPost  =
      meta        : data.meta
      title       : data.title
      body        : data.body
      group       : data.group
    JPost.create.call @, client, blogPost, callback

  modify: secure (client, data, callback)->
    JMarkdownDoc = require '../../markdowndoc'
    blogPost =
      meta        : data.meta
      title       : data.title
      body        : data.body
    JPost::modify.call @, client, blogPost, callback

  reply: permit 'reply to posts',
    success:(client, comment, callback)->
      JComment = require '../comment'
      JPost::reply.call @, client, JComment, comment, callback