class AccountReferralSystemListController extends AccountListViewController

  constructor: (options, data)->
    options.noItemFoundText = "You dont have any referal."
    super options, data

  loadItems: ->
    @removeAllItems()
    #    @showLazyLoader yes

    da = [{name:"hede"},{name:"hede2"},{name:"hede3"}]
    @instantiateListItems da
    @hideLazyLoader()

  loadView: ->
    super
    @loadItems()

    @getView().parent.addSubView getYourRefererCode = new KDCustomHTMLView
      tagName      : "a"
      partial      : "Get Your Referer Code"
      cssClass     : "action-link"
      attributes   :
        href       : "#"
      click     : =>
        shareUrl      = "#{location.origin}/?r=#{KD.whoami().refererCode}"
        getYourRefererCode._shorten = shareUrl

        contextMenu   = new JContextMenu
          cssClass    : "activity-share-popup"
          type        : "activity-share"
          delegate    : getYourRefererCode
          x           : getYourRefererCode.getX() - 35
          y           : getYourRefererCode.getY() - 50
          arrow       :
            placement : "bottom"
            margin    : 110
          lazyLoad    : yes
        , customView  : new ActivitySharePopup delegate: this, url: shareUrl

        new KDOverlayView
          parent      : KD.singletons.mainView.mainTabView.activePane
          transparent : yes


class AccountReferralSystemList extends KDListView

  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountReferralSystemListItem
    ,options
    super options,data


class AccountReferralSystemListItem extends KDListItemView
  constructor: (options, data)->
    options =
      tagName: "li"
    super options, data

  viewAppended: ->
    super

  click: (event)->
    alert "naber  click"

  partial: (data)->
    """
    buralar hep dutluktu #{data.name}
    """
