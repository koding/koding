kd = require 'kd'
CommentListPreviousLink = require './commentlistpreviouslink'
CommentView = require './commentview'
ReplyListViewController = require './replylistviewcontroller'
showError = require 'app/util/showError'


module.exports = class ReplyView extends CommentView

  {noop} = kd

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'comment-container replies', options.cssClass
    options.controllerClass = ReplyListViewController

    super options, data

    @listPreviousLink.destroy()
    @listPreviousLink = new CommentListPreviousLink
      delegate : @listController
      click    : @bound 'listPreviousReplies'
      linkCopy : 'Show previous replies'
    , data

  reply: (body, callback = noop) ->

    {channelId}  = @getOptions()
    {appManager} = kd.singletons

    appManager.tell 'Activity', 'sendPrivateMessage', {channelId, body}, (err, reply) =>
      return showError err  if err
