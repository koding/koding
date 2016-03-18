kd               = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView   = kd.ListItemView

groupifyLink     = require 'app/util/groupifyLink'


module.exports = class SidebarItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.type       or= 'sidebar-item'
    options.route        = groupifyLink "/Activity/#{options.route}"
    options.tagName    or= 'a'
    options.attributes or= { href : options.route }
    options.attributes.testpath = "public-feed-link#{options.route}"

    super options, data

    @count       = 0
    @unreadCount = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'count hidden'

    # this is used to store the last timestamp once it is clicked
    # to avoid selecting multiple items in case of having the same item
    # on multiple sidebar sections e.g. having the same topic on both
    # "FOLLOWED Topics" and "HOT Topics" sections
    @lastClickedTimestamp = 0

    @on 'click', (event) =>
      @getDelegate().emit 'ItemShouldBeSelected', this, event
      @lastClickedTimestamp = Date.now()


    # `unreadRepliesCount` is used for pinned messages, pinned message list is the
    # only place where we are displaying message items, for other places (my
    # feeds and private messages) they are channels and channels have their
    # unread count in the data as `unreadCount`
    @once 'viewAppended', => @setUnreadCount @getData().unreadCount or @getData().unreadRepliesCount


  setUnreadCount: (unreadCount = 0) ->

    @count = unreadCount

    if unreadCount is 0
      @unreadCount.hide()
      @unsetClass 'unread'
    else
      @unreadCount.updatePartial unreadCount
      @unreadCount.show()
      @setClass 'unread'
