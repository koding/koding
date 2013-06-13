class AccountSubscriptionsListController extends KDListViewController
  constructor:(options,data)->
    data = $.extend
      items : [
        { title : "Subscriptions are coming soon" }
        # { title : "Basic Environment",          createdAt : "01/01/2011", nextBillAt : "n/a",        price : "free", currency : "",   billingCycle : null }
        # { title : "Dedicated C++ Environment",  createdAt : "04/05/2011", nextBillAt : "12/05/2011", price : "10",   currency : "$",  billingCycle : "monthly" }
        # { title : "Heroku Compatible RoR",      createdAt : "04/05/2011", nextBillAt : "12/05/2011", price : "3",    currency : "$",  billingCycle : "monthly" }
      ]
    ,data
    super options,data

  loadView:->
    super
    # @getView().parent.addSubView addButton = new KDButtonView
    #   style     : "clean-gray account-header-button"
    #   title     : ""
    #   icon      : yes
    #   iconOnly  : yes
    #   iconClass : "plus"
    #   callback  : =>
    #     @getListView().showModal()

class AccountSubscriptionsList extends KDListView
  constructor:(options,data)->
    options = $.extend
      tagName      : "ul"
      itemClass : AccountSubscriptionsListItem
    ,options
    super options,data

  showModal:->
    modal = new KDModalView
      title     : "Your cool new package"
      overlay   : yes
      cssClass  : "new-kdmodal"
      width     : 500
      height    : 300
      content   : "Not available on Private Beta"
      buttons   :
        "Add Subscription" :
          style     : "modal-clean-gray"
          callback  : (event)->
            modal.destroy()
        Cancel   :
          style     : "modal-cancel"
          callback  : (event)->
            modal.destroy()

    modal.addSubView helpBox = new HelpBox, ".kdmodal-buttons"


class AccountSubscriptionsListItem extends KDListItemView
  constructor:(options,data)->
    options = tagName : "li"
    super options,data

  # viewAppended:->
  #   super
  #   @addSubView editLink = new KDCustomHTMLView
  #     tagName      : "a"
  #     cssClass     : "delete-icon"

  click:(event)->
    if $(event.target).is "a.delete-icon"
      @getDelegate().emit "UnlinkAccount", accountType : @getData().type

  partial:(data)->
    """
      <span class='darkText'>#{data.title}</span>
    """
    # cycleNotice = if data.billingCycle then "/#{data.billingCycle}" else ""
    # """
    #   <div class='labelish'>
    #     <span class='subscription-title'>#{data.title}</span>
    #   </div>
    #   <div class='swappableish swappable-wrapper posstatic'>
    #     <p class='lightText'><strong>#{data.currency}#{data.price}#{cycleNotice}</strong> - <a href='#'>Not available on Private Beta</a></p>
    #     <p class='darkText'>created at #{data.createdAt}</p>
    #     <p class='darkText'>next bill date is #{data.nextBillAt}</p>
    #   </div>
    # """
