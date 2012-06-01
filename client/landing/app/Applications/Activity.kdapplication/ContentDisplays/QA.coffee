class ContentDisplayQuestionUpdate extends KDView
  constructor: (options, data) ->
    super
    @setClass 'activity-item firstpost postauthor clearfix'
    
  viewAppended: ->
    activity = @getData()
    Cacheable.account.id(activity.origin).ready (error, account) =>
      @addSubView new ContentDisplayAuthorAvatar {}, {activity, account}
      @addSubView new ContentDisplayQuestionTopic {cssClass: 'topictext'}, {activity, account}
    
class ContentDisplayQuestionTopic extends KDView
  viewAppended: ->
    {activity, account} = @getData()
    
    @addSubView new KDCustomHTMLView('p').setPartial "title: #{activity.questionTitle}"
    @addSubView new KDCustomHTMLView('p').setPartial "content: #{activity.questionContent}"
    
    @addSubView new ContentDisplayMeta {cssClass: 'topicmeta'}, @getData()
    @addSubView new ContentDisplayComments {}, @getData()