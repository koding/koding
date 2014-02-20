class FeedCoverPhotoView extends KDView

  _notify = (msg)-> new KDNotificationView title : msg or 'There was an error, please try again later!'

  constructor: (options = {}, data) ->
    options.cssClass = "group-cover-view"
    super options, data

    {groupsController} = KD.singletons

    groupsController.ready =>
      @group = groupsController.getCurrentGroup()

      @decorateHeader()  if @group.slug isnt "koding"

      @group.on "update", =>
        if @group.slug isnt "koding"
          @decorateHeader()

  getResizedImage:(imageToCrop)->
    proxifyOptions =
      crop         : yes
      width        : 950
      height       : 315
    KD.utils.proxifyUrl imageToCrop, proxifyOptions

  decorateHeader:->

    unless @container
      @container = new KDView
        cssClass : "container"
        size     : height : 315

      resizedImg = @getResizedImage(@group.customize?.coverPhoto)
      @coverView = new KDCustomHTMLView
        tagName    : 'figure'
        attributes :
          style    : "background-image: url(#{resizedImg});"

      @listController = new KDListViewController
        startWithLazyLoader : no
        view                : new KDListView
          type              : "collage"
          cssClass          : "cover-list"
          itemClass         : CollageItemList


      @container.addSubView @getCoverUpdateButton()
      @container.addSubView @coverView
      @container.addSubView @listController.getView()
      @addSubView @container

    @toggle()

  toggle:->

    if @group.customize?.coverPhoto
      @listController.getView().hide()
      resizedImg = @getResizedImage(@group.customize?.coverPhoto)
      @coverView.setCss 'background-image', "url(#{resizedImg})"
      @coverView.show()
    else
      @coverView.hide()
      @listController.getView().show()
      @listController.removeAllItems()
      @group.fetchMembers {},limit : 20, (err, accounts) =>
        @listController.instantiateListItems accounts


  getCoverUpdateButton: ->
    if "admin" in KD.config.roles
      new KDButtonView
        style     : "solid green small update-cover"
        icon      : yes
        type      : "submit"
        title     : "Update cover image"
        callback  : =>
          modal = new UploadImageModalView
            cssClass      : "group-cover-uploader"
            title         : "Change Cover Photo"
            uploaderTitle : "Drag & drop image here! <small>Cover photos are 948 pixels wide and 315 pixels tall.</small>"
            width         : 1004
            image         :
              type        : "coverPhoto"
              size        :
                width     : 914
                height    : 315
            buttons       :
              uploadButton:
                title     : "Upload"
                cssClass  : "modal-clean-green"
                callback  : =>
                  modal.upload (err)=>
                    return  if err then _notify()
                    modal.destroy()

              clear       :
                title     : "Remove cover photo"
                cssClass  : "modal-clean-red"
                callback  : =>
                  @group.modify "customize.coverPhoto" : "", (err)=>
                    return _notify()  if err
                    modal.destroy()
    else
      new KDCustomHTMLView


class CollageItemList extends KDListItemView
  constructor: (options = {}, data) ->

    super options, data
    @avatar    = new AvatarView
      size     :
        width  : 158
        height : 158
    , @getData()

  viewAppended:JView::viewAppended

  pistachio:->
    """
      {{> @avatar}}
    """
