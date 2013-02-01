class AvatarPopupGroupSwitcher extends AvatarPopup

  viewAppended:->

    super

    @_popupList = new PopupList
      itemClass  : PopupGroupListItem

    @listController = new KDListViewController
      view         : @_popupList

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'

    @avatarPopupContent.addSubView @noMessage = new KDView
      height   : "auto"
      cssClass : "sublink hidden"
      partial  : "You haven't joined to any groups..."

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "Switch to:"

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all groups...</a>"
      click    : @bound 'hide'

  accountChanged:->
    @listController.removeAllItems()

  show:->

    super

    KD.remote.api.JGroup.streamModels {},{}, (err, res)=>
      if err then warn err
      else if res
        @listController.addItem res[0]
      else
        log 'selin naber butun gruplar geldi'





class PopupGroupListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName or= "li"

    super

    @switchLink = new CustomLinkView
      title : @getData().title

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <span class='avatar'></span>
    <div class='right-overflow'>
      {{> @switchLink}}
      <footer>
        {{ #(visibility)}}
      </footer>
    </div>
    """


