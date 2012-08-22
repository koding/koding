class JOpinion extends JPost


class JDiscussion extends JPost

  {secure} = require 'bongo'
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
      title 	: data.title
      body		: data.body
      meta		: data.meta
    JPost.create.call @, client, discussion, callback


  modify: secure (client, data, callback)->
    discussion =
      title   : data.title
      body    : data.body
      meta    : data.meta
    JPost::modify.call @, client, discussion, callback

  reply: secure (client, opinion, callback)->
    JOpinion.create.call @, client, opinion, callback

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
