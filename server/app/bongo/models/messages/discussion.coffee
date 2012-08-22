class JOpinion extends JPost
  {secure} = bongo
  {Relationship} = jraphical
  {once} = require 'underscore'

  @share()

  @getActivityType =-> CDiscussionActivity

  @getAuthorType =-> JAccount

  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    relationships : JPost.relationships

  @create = secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost.create.call @, client, codeSnip, callback

  modify: secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost::modify.call @, client, codeSnip, callback

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback
class JDiscussion extends JPost

  # broken : tag support
  {secure} = bongo
  {Relationship} = jraphical
  {once} = require 'underscore'

  @share()

  @getActivityType =-> CDiscussionActivity

  @getAuthorType =-> JAccount

  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    relationships     :
      opinion         : JOpinion
      participant     :
        targetType    : JAccount
        as            : ['author','commenter']
      likedBy         :
        targetType    : JAccount
        as            : 'like'
      repliesActivity :
        targetType    : CRepliesActivity
        as            : 'repliesActivity'
      tag             :
        targetType    : JTag
        as            : 'tag'
      follower        :
        as            : 'follower'
        targetType    : JAccount

  @create = secure (client, data, callback)->
    discussion =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost.create.call @, client, discussion, callback

  modify: secure (client, data, callback)->
    discussion =
      title       : data.title
      body        : data.body
      meta        : data.meta
    JPost::modify.call @, client, discussion, callback

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JOpinion, comment, callback

  fetchEntireMessage:(callback)->
    @beginGraphlet()
      .edges
        query         :
          targetName  :'JOpinion'
        sort          :
          timestamp   : 1
      .nodes()
    .endGraphlet()
    .fetchRoot callback

class CDiscussionActivity extends CActivity

  @share()

  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JDiscussion
        as          : 'content'
