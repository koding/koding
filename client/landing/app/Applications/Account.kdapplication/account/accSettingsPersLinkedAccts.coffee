class AccountLinkedAccountsListController extends KDListViewController

  constructor:(options = {}, data)->

    data =
      items : [
        { title : "GitHub", type : "github", linked : no, account : ""},
        { title : "Odesk", type : "odesk", linked : no, account : ""},
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

  getProvider:(name)->
    if name is "github" then @githubProvider else @odeskProvider

  click:(event)->
    {type} = @getData()

    if $(event.target).is "a.delete-icon"
      @getDelegate().emit "UnlinkAccount", accountType : type

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
      unless @getProvider() # TODO: why is this here?
        if type is "github"
          KD.utils.openGithubPopUp()
        else
          KD.utils.openOdeskPopUp()

  viewAppendedHelper:->
    @setTemplate @pistachio()
    @template.update()

  viewAppended:->
    KD.remote.api.JUser.fetchUser (err, user)=>
      @githubProvider = user.foreignAuth?.github
      @odeskProvider  = user.foreignAuth?.odesk
      @viewAppendedHelper()

  getLinkedString:(provider)->
    if @getProvider(@getData().type) then "Linked" else "Not linked."

  getLinkedClass:(provider)->
    if @getProvider(@getData().type) then "yes" else "no"

  getAccountString:(provider)->
    if @getProvider(@getData().type) then "" else "Link now."

  pistachio:->
    """
    <div class='linked-account-title'>
      <span class='icon github'></span>
      <cite>#{@getData().title}</cite>
      <a href='#' class='delete-icon #{@getLinkedClass()}'></a>
    </div>

    <div class='linked-status #{@getLinkedClass()}'>
      <span class='icon-check'></span>
      <span>#{@getLinkedString()}</span>
      <a href="#">#{@getAccountString()}</a>
    </div>
    """
