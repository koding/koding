class ContentDisplayLink extends KDView
  constructor: (options, data) ->
    super
    @setClass 'activity-item firstpost postauthor clearfix'
    
  viewAppended: ->
    activity = @getData()
    Cacheable.account.id(activity.origin).ready (error, account) =>
      @addSubView new ContentDisplayAuthorAvatar {}, {activity, account}
      @addSubView new ContentDisplayLinkTopic {cssClass: 'topictext'}, {activity, account}
    
class ContentDisplayLinkTopic extends KDView
  viewAppended: ->
    {activity, account} = @getData()
    
    @addSubView new KDCustomHTMLView('p').setPartial "title: #{activity.link}"
    @addSubView new KDCustomHTMLView('p').setPartial "link: #{activity.body}"
    
    @addSubView new ContentDisplayMeta {cssClass: 'topicmeta'}, @getData()
    @addSubView new ContentDisplayComments {}, @getData()
    

