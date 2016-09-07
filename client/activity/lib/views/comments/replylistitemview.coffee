kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDTimeAgoView = kd.TimeAgoView
CommentListItemView = require './commentlistitemview'
CommentTimeView = require './commenttimeview'
ReplyLikeView = require '../replylikeview'
ProfileLinkView = require 'app/commonviews/linkviews/profilelinkview'
JView = require 'app/jview'
JCustomHTMLView = require 'app/jcustomhtmlview'
AvatarView = require 'app/commonviews/avatarviews/avatarview'
applyTextExpansions = require 'app/util/applyTextExpansions'

module.exports = class ReplyListItemView extends CommentListItemView


  constructor: (options = {}, data) ->

    options.type = 'comment'

    super options, data

    (kd.singleton 'mainController').on 'AccountChanged', @bound 'addMenu'

    data = @getData()
    {account} = data
    {createdAt, deletedAt, updatedAt} = data

    origin            =
      constructorName : account.constructorName
      id              : account._id

    @avatar       = new AvatarView
      origin      : origin
      showStatus  : yes
      size        :
        width     : 38
        height    : 38

    @author = new ProfileLinkView {origin}

    @body       = new JCustomHTMLView
      cssClass  : 'comment-body-container'
      pistachio : '{p{applyTextExpansions #(body), yes}}'
    , data

    @formWrapper = new KDCustomHTMLView cssClass: 'edit-comment-wrapper hidden'

    @editInfo   = new JCustomHTMLView
      tagName   : 'span'
      cssClass  : 'hidden edited'
      pistachio : 'edited'

    @editInfo.show()  if updatedAt > createdAt

    # if deleterId? and deleterId isnt origin.id
    #   @deleter = new ProfileLinkView {}, data.getAt 'deletedBy'

    @menuWrapper = new KDCustomHTMLView
    @addMenu()
    @createReplyLink()

    @likeView    = new ReplyLikeView {}, data
    @timeAgoView = new KDTimeAgoView {}, createdAt
    @timeView    = new CommentTimeView {}, createdAt

  viewAppended: JView::viewAppended


  pistachio: ->
    '''
    {{> @avatar}}
    <div class='comment-contents clearfix'>
    {{> @author}} <div class='stats'>{{> @timeView}} {{> @timeAgoView}} {{> @likeView}}</div>
    {{> @body}}
    {{> @formWrapper}}
    {{> @editInfo}}
    {{> @menuWrapper}}
    </div>
    '''
