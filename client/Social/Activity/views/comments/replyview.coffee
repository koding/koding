class ReplyView extends CommentView

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry 'comment-container replies', options.cssClass
    options.controllerClass = ReplyListViewController

    super options, data

    @listPreviousLink.destroy()
    @listPreviousLink = new CommentListPreviousLink
      delegate : @controller
      click    : @bound 'listPreviousReplies'
      linkCopy : 'Show previous replies'
    , data

  reply: (body, callback = noop) ->

    {channelId}  =  @getOptions()
    {appManager} = KD.singletons

    appManager.tell 'Activity', 'sendPrivateMessage', {channelId, body}, (err, reply) =>
      return KD.showError err  if err
