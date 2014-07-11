class ReplyView extends CommentView

  hasSameOwner = (a, b) -> a.getData().account._id is b.getData().account._id

  constructor: (options = {}, data) ->

    options.cssClass        = KD.utils.curry 'comment-container replies', options.cssClass
    options.controllerClass = ReplyListViewController

    super options, data

    @controller.getListView()
      .on 'ItemWasAdded',   @bound 'itemAdded'
      .on 'ItemWasRemoved', @bound 'itemRemoved'

    @listPreviousLink.destroy()
    @listPreviousLink = new CommentListPreviousLink
      delegate : @controller
      click    : @bound 'listPreviousReplies'
      linkCopy : 'Show previous replies'
    , data

  itemAdded: (item, index) ->

    prevSibling = @controller.getListItems()[index-1]
    nextSibling = @controller.getListItems()[index+1]

    if prevSibling
      if hasSameOwner item, prevSibling
      then item.setClass 'consequent'
      else item.unsetClass 'consequent'

    if nextSibling
      if hasSameOwner item, nextSibling
      then nextSibling.setClass 'consequent'
      else nextSibling.unsetClass 'consequent'


  itemRemoved: (item, index) ->

    prevSibling = @controller.getListItems()[index-1]
    nextSibling = @controller.getListItems()[index]

    if nextSibling and prevSibling
      if hasSameOwner prevSibling, nextSibling
      then nextSibling.setClass 'consequent'
      else nextSibling.unsetClass 'consequent'
    else if nextSibling
      nextSibling.unsetClass 'consequent'
