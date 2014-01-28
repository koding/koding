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

      container.addSubView @getCoverUpdateButton()
      container.addSubView @getCoverView()
    else
      container = new KDCustomHTMLView

    @addSubView container

  getCoverUpdateButton: ->
    if "admin" in KD.config.roles
      new KDButtonView
        style     : "solid green small update-cover"
        icon      : yes
        type      : "submit"
        title     : "Update cover image"
        callback  : =>
          new UploadImageModalView
            cssClass   : "group-cover-uploader"
            title      : "Change Cover Photo"
            width      : 1004
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
        tagName     : 'figure'
        attributes  :
          style     : "background:url(#{group.customize?.coverPhoto})"
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
        width  : 158
        height : 158
    , @getData()

  viewAppended:JView::viewAppended

  pistachio:->
    """
      {{> @avatar}}
    """
