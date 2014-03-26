class ActivityItemChild extends KDView

#  showAuthor =(author)->
#    KD.getSingleton('router').handleRoute "/#{author.profile.nickname}", state: author

  constructor:(options, data)->

    currentGroup = KD.getSingleton("groupsController").getCurrentGroup()

    getContentGroupLinkPartial = (groupSlug, groupName)->
      if currentGroup?.slug is groupSlug
      then ""
      else "In <a href=\"#{groupSlug}\" target=\"#{groupSlug}\">#{groupName}</a>"

    @contentGroupLink = new KDCustomHTMLView
      tagName     : "span"
      partial     : getContentGroupLinkPartial(data.group, data.group)

    if currentGroup?.slug is data.group
      @contentGroupLink.updatePartial getContentGroupLinkPartial(currentGroup.slug, currentGroup.title)
    else
      KD.remote.api.JGroup.one {slug:data.group}, (err, group)=>
        if not err and group
          @contentGroupLink.updatePartial getContentGroupLinkPartial(group.slug, group.title)

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarView {
      size        : width: 55, height: 55
      cssClass    : "author-avatar"
      origin
      showStatus  : yes
    }

    @author = new ProfileLinkView { origin }

    # for discussion, switch to the View that supports nested structures
    # JDiscussion,JTutorial
    # -> JOpinion
    #    -> JComment
    if data.bongo_.constructorName in ["JDiscussion","JTutorial"]
      @commentBox = new OpinionView {}, data
      list        = @commentBox.opinionList
    else
      commentSettings = options.commentSettings or null
      @commentBox = new CommentView commentSettings, data
      list        = @commentBox.commentList

    @actionLinks = new ActivityActionsView
      cssClass : "comment-header"
      delegate : list
    , data

    @settingsButton = new ActivitySettingsView itemView: this, data

    super options, data

    data = @getData()

    deleteActivity = (activityItem)=>
      activityItem.destroy() #FIXME
      # activityItem.slideOut -> activityItem.destroy()
      @emit 'ActivityIsDeleted'

    @settingsButton.on 'ActivityIsDeleted', =>
      activityItem = @getDelegate()
      deleteActivity activityItem

    resetEditing = =>
      @editWidget.destroy()
      @editWidgetWrapper.setClass "hidden"

    @settingsButton.on 'ActivityEditIsClicked', =>
      @editWidget = new ActivityEditWidget null, data
      @editWidget.on 'Submit', resetEditing
      @editWidget.on 'Cancel', resetEditing
      @editWidgetWrapper.addSubView @editWidget, null, yes
      @editWidgetWrapper.unsetClass "hidden"

    data.on 'PostIsDeleted', =>
      activityItem = @getDelegate()
      return unless activityItem.isInDom()

      if KD.whoami().getId() is data.getAt('originId')
        deleteActivity activityItem
      else
        #CtF: FIXME added just for making it functional
        activityItem.destroy()

        # activityItem.putOverlay
        #   isRemovable : no
        #   parent      : @parent
        #   cssClass    : 'half-white'

        # @utils.wait 30000, ->
        #   activityItem.slideOut -> activityItem.destroy()


    data.watch 'repliesCount', (count)=>
      @commentBox.decorateCommentedState() if count >= 0

    KD.remote.cacheable data.originType, data.originId, (err, account)=>
      @setClass "exempt" if account and KD.checkFlag 'exempt', account



  click: KD.utils.showMoreClickHandler

  viewAppended:->
    super

    if @getData().fake
      @actionLinks.setClass 'hidden'

class ActivityItemMenuItem extends JView
  pistachio :->
    {title} = @getData()
    slugifiedTitle = KD.utils.slugify title
    """
    <i class="#{slugifiedTitle} icon"></i>#{title}
    """
