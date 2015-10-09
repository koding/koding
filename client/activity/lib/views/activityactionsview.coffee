kd = require 'kd'
KDContextMenu = kd.ContextMenu
KDLoaderView = kd.LoaderView
ActivityCommentCount = require './comments/activitycommentcount'
ActivityLikeView = require './activitylikeview'
ActivitySharePopup = require './activitysharepopup'
groupifyLink = require 'app/util/groupifyLink'
JView = require 'app/jview'
CustomLinkView = require 'app/customlinkview'


module.exports = class ActivityActionsView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "activity-actions comment-header", options.cssClass

    super options, data

    @commentLink  = new CustomLinkView
      title: "Comment"
      click: @bound "reply"

    @commentCount = new ActivityCommentCount
      cssClass    : 'count'
      tooltip     :
        title     : "Show all"
      click       : (event) =>
        kd.utils.stopDOMEvent event
        @getDelegate().emit "CommentCountClicked", this
    , data

    @shareLink = new CustomLinkView
      title : "Share"
      click : (event) =>

        kd.utils.stopDOMEvent event

        url      = "Activity/Post/#{data.slug}"
        shareUrl = groupifyLink(url, yes)

        {scrollX, scrollY} = global

        @sharePopup = new KDContextMenu
          cssClass    : "activity-share-popup"
          type        : "activity-share"
          delegate    : this
          x           : @shareLink.getX() + scrollX + 25
          y           : @shareLink.getY() + scrollY - 12
          menuMaxWidth: 400
          menuMinWidth: 192
          lazyLoad    : yes
        , customView  : new ActivitySharePopup delegate: this, url: shareUrl

        pane = kd.singletons.appManager.frontApp.getView().tabs.getActivePane()

        pane.scrollView.wrapper.once 'scroll', @sharePopup.bound 'destroy'

    @likeView = new ActivityLikeView {}, data

    @loader = new KDLoaderView
      cssClass      : 'action-container'
      size          :
        width       : 12
      loaderOptions :
        color       : '#6B727B'

    options.delegate
      .on "AsyncJobStarted",  @loader.bound "show"
      .on "AsyncJobFinished", @loader.bound "hide"


  reply: (event) ->

    kd.utils.stopDOMEvent event
    @emit "Reply"


  viewAppended: ->

    @loader.hide()

    super


  pistachio: ->

    """
    <span class='logged-in action-container'>
    {{> @likeView}}
    </span>
    <span class='logged-in action-container'>
    {{> @commentLink}}{{> @commentCount}}
    </span>
    <span class='optional action-container'>
    {{> @shareLink}}
    </span>
    {{> @loader}}
    """
