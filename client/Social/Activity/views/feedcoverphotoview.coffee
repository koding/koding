class FeedCoverPhotoView extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = "group-cover-view"
    super options, data

    @addSubView @getCoverView()

  getCoverView: ->
    group = KD.singletons.groupsController.getCurrentGroup()
    return new KDCustomHTMLView if group.slug is "koding"
    if group.customize.background.coverPhoto
      new KDCustomHTMLView
        tagName     : 'img'
        size        :
            width   : 942
            height  : 315
        attributes  :
          src       : group.customize.background.coverPhoto
          title     : group.title or ''
    else
      # if group doesnt has cover photo, put collage
      collageList  = new KDListViewController
        startWithLazyLoader : no
        view                : new KDListView
          type              : "collage"
          cssClass          : "cover-list"
          itemClass         : CollageItemList

      options =
        limit : 20

      group.fetchMembersFromGraph options, (err, accounts) ->
        collageList.instantiateListItems accounts

      collageList.getView()

class CollageItemList extends KDListItemView
  constructor: (options = {}, data) ->

    super options, data
    @avatar    = new AvatarImage
      size     :
        width  : 100
        height : 100
    , @getData()

  viewAppended:JView::viewAppended

  pistachio:->
    """
      {{> @avatar}}
    """
