class AvatarPopupGroupSwitcher extends AvatarPopup

  viewAppended:->

    super

    @_popupList = new PopupList
      itemClass  : PopupGroupListItem

    @listController = new KDListViewController
      view         : @_popupList

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'


    @avatarPopupContent.addSubView switchToTitle = new KDView
      height   : "auto"
      cssClass : "sublink top"
      partial  : "Switch to:"

    switchToTitle.addSubView new KDCustomHTMLView
      tagName    : 'span'
      cssClass   : 'icon help'
      tooltip    :
        title    : "Here you'll find the groups that you are a member of, clicking one of them will take you to a new browser tab."

    @avatarPopupContent.addSubView @loader = new KDLoaderView
      size    :
        width : 20

    @loader.hide()

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all groups...</a>"
      click    : =>
        appManager.openApplication "Groups"
        @hide()

  accountChanged:->
    @listController.removeAllItems()

  populateGroups:->
    @listController.removeAllItems()
    @loader.show()
    KD.remote.api.JGroup.streamModels {},{}, (err, res)=>
      if err then warn err
      else if res?.length
        @loader.hide()
        @listController.addItem res[0]

  show:->
    super
    @populateGroups()

class PopupGroupListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName or= "li"

    super

    {title, avatar} = @getData()

    @avatar = new KDCustomHTMLView
      tagName    : 'img'
      cssClass   : 'avatar-image'
      attributes :
        src      : avatar or "http://lorempixel.com/20/20?#{@utils.getRandomNumber()}"

    @switchLink = new CustomLinkView
      title       : title
      icon        :
        cssClass  : 'new-page'
        placement : 'right'
        tooltip   :
          title   : "Opens in a new browser window."
          delayIn : 300

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <span class='avatar'>{{> @avatar}}</span>
    <div class='right-overflow'>
      {{> @switchLink}}
    </div>
    """


