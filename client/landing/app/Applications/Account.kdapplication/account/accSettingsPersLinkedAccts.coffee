class AccountLinkedAccountsListController extends KDListViewController

  constructor:(options = {}, data)->

    data =
      items : [
        { title : "GitHub",   type : "github",    linked : no, account : ""}
      ]

    super options, data


class AccountLinkedAccountsList extends KDListView

  constructor:(options = {}, data)->

    options.tagName   or= "ul"
    options.itemClass or= AccountLinkedAccountsListItem

    super options,data

    #@on "UnlinkAccount", (event)=>
    #  for itemData,k in @data.items
    #    if itemData.type is event.accountType
    #      # FIXME: this needs to be done in controller with real stuff
    #      delete itemData.account
    #      itemData.linked = no
    #      @items[k].data = @data.items[k] = itemData
    #      @items[k].$().html ""
    #      @items[k].viewAppended()


class AccountLinkedAccountsListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName or= "li"

    super options, data

    @provider = null

    mainController = KD.getSingleton "mainController"
    mainController.on "ForeignAuthSuccess", (provider)=>
      @provider = provider
      @viewAppendedHelper()

  getProvider:-> @provider

  click:(event)->
    if $(event.target).is "a.delete-icon"
      {type} = @getData()
      @getDelegate().emit "UnlinkAccount", accountType : @getData().type

      notify = (message)->
        new KDNotificationView
          title : message

      KD.whoami().unlinkOauth type, (err)=>
        if err then KD.showError err
        else
          notify "Your '#{type}' account is now unlinked."
          @provider = null
          @viewAppendedHelper()
    else
      KD.utils.openGithubPopUp()  unless @getProvider()

  viewAppendedHelper:->
    @setTemplate @pistachio()
    @template.update()

  viewAppended:->
    KD.remote.api.JUser.fetchUser (err, user)=>
      @provider = user.foreignAuth?.github
      @viewAppendedHelper()

  getLinkedString:->
    if @getProvider() then "Linked" else "Not linked."

  getLinkedClass:->
    if @getProvider() then "yes" else "no"

  getAccountString:->
    if @getProvider() then "" else "Link now."

  pistachio:->
    """
    <div class='linked-account-title'>
      <span class='icon github'></span>
      <cite>Github</cite>
      <a href='#' class='delete-icon #{@getLinkedClass()}'></a>
    </div>

    <div class='linked-status #{@getLinkedClass()}'>
      <span class='icon-check'></span>
      <span>#{@getLinkedString()}</span>
      <a href="#" title="Not available on Private Beta">#{@getAccountString()}</a>
    </div>
    """
