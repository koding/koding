class AccountLinkedAccountsListController extends KDListViewController

  constructor:(options = {}, data)->

    data =
      items : [
        { title : "GitHub",   type : "github",    linked : no, account : ""}
        { title : "Facebook", type : "facebook",  linked : no, account : ""}
        { title : "Twitter",  type : "twitter",   linked : no, account : ""}
        { title : "Google",   type : "google",    linked : no}
      ]

    super options, data


class AccountLinkedAccountsList extends KDListView

  constructor:(options = {}, data)->

    options.tagName   or= "ul"
    options.itemClass or= AccountLinkedAccountsListItem

    super options,data

    @on "UnlinkAccount", (event)=>
      for itemData,k in @data.items
        if itemData.type is event.accountType
          # FIXME: this needs to be done in controller with real stuff
          delete itemData.account
          itemData.linked = no
          @items[k].data = @data.items[k] = itemData
          @items[k].$().html ""
          @items[k].viewAppended()


class AccountLinkedAccountsListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName or= "li"

    super options, data

  click:(event)->
    if $(event.target).is "a.delete-icon"
      @getDelegate().emit "UnlinkAccount", accountType : @getData().type

  partial:(data)->
    linkedString  = if data.linked then "Linked to" else "Not linked"
    linkedClass   = if data.linked then "yes" else "no"
    accountString = if data.account then data.account else "Link now. (Not available on Private Beta)"

    """
    <div class='linked-account-title'>
      <span class='icon #{data.type}'></span>
      <cite>#{data.title}</cite>
    </div>
    <div class='linked-status #{linkedClass}'>
      <span class='icon-check'></span>
      <span>#{linkedString}</span>
      <a href="#" title="Not available on Private Beta">#{accountString}</a>
    </div>
    <a href='#' class='delete-icon #{linkedClass}'></a>
    """
