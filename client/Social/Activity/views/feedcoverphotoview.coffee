class FeedCoverPhotoView extends KDView
  constructor: (options = {}, data) ->
    options.cssClass = "group-cover-view"
    super options, data

    group = KD.singletons.groupsController.getCurrentGroup()

    if group.slug isnt "koding"
      container = new KDView
        cssClass : "container"
        size     :
          height : 315
          width  : 914

      container.addSubView @getCoverUpdateButton()
      container.addSubView @getCoverView()
    else
      container = new KDCustomHTMLView

    @addSubView container

  getCoverUpdateButton: ->
    if "admin" in KD.config.roles
      new KDButtonView
        style     : "solid green small"
        type      : "submit"
        title     : "update cover photo"
        callback  : =>
          new UploadImageModalView
            title      : "Change Cover Photo"
            image      :
              type     : "coverPhoto"
              size     :
                width  : 914
                height : 315

    else
      new KDCustomHTMLView

  getCoverView: ->
    group = KD.singletons.groupsController.getCurrentGroup()
    if group.customize?.coverPhoto
      new KDCustomHTMLView
        tagName     : 'img'
        attributes  :
          src       : group.customize?.coverPhoto
          title     : group.title or ''
    else
      # if group doesnt has cover photo, put collage of group users
      collageList           = new KDListViewController
        startWithLazyLoader : no
        view                : new KDListView
          type              : "collage"
          cssClass          : "cover-list"
          itemClass         : CollageItemList

      options = limit : 20

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
