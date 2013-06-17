class StaticActivityItemChild extends KDView

  constructor:(options, data)->

    origin =
      constructorName  : data.originType
      id               : data.originId

    @author = new ProfileLinkView { origin }

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      itemClass  : StaticTagLinkView
    , data.tags

    likeCount = data.meta.likes

    # @actionLinks = new KDView
    #   cssClass : 'static-action-links'
    #   partial : if likeCount > 0 then "#{likeCount} Like#{if likeCount is 1 then '' else 's'}" else ""

    @actionLinks = new StaticActivityActionsView delegate : @, cssClass : "", data

    super

    data = @getData()
    data.on 'TagsChanged', (tagRefs)=>
      KD.remote.cacheable tagRefs, (err, tags)=>
        @getData().setAt 'tags', tags
        @tags.setData tags
        @tags.render()

    data.on 'PostIsDeleted', =>
      activityItem = @getDelegate()
      if KD.whoami().getId() is data.getAt('originId')
        activityItem.slideOut -> activityItem.destroy()
      else
        activityItem.putOverlay
          isRemovable : no
          parent      : @parent
          cssClass    : 'half-white'

        @utils.wait 30000, ->
          activityItem.slideOut -> activityItem.destroy()

    @contentDisplayController = KD.getSingleton "contentDisplayController"

    KD.remote.cacheable data.originType, data.originId, (err, account)=>
      @setClass "exempt" if account and KD.checkFlag 'exempt', account

  formatCreateDate:(date = new Date())->
    "Published on #{dateFormat(date, 'mmmm dS, yyyy')}"

class StaticActivityActionsView extends ActivityActionsView
  viewAppended:->
    @setClass "static-activity-actions"
    @setTemplate @pistachio()
    @template.update()
    @attachListeners()
    @loader.hide()

class StaticTagLinkView extends TagLinkView
  click:(event)->
    event.stopPropagation()
    event.preventDefault()
    KD.getSingleton('staticProfileController').emit 'StaticInteractionHappened', @
