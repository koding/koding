class AccountLinkedAccountsListController extends KDListViewController

  constructor:(options = {}, data)->

    data = items : ({title : nicename, provider} for own provider, {nicename} of MembersAppController.externalProfiles)

    super options, data


class AccountLinkedAccountsList extends KDListView

  constructor:(options = {}, data)->

    options.tagName   or= "ul"
    options.itemClass or= AccountLinkedAccountsListItem

    super options,data


class AccountLinkedAccountsListItem extends KDListItemView

  notify = (message)-> new KDNotificationView title : message, type : 'mini', duration : 3000


  constructor:(options = {}, data)->

    options.tagName or= "li"
    options.type    or= "oauth"

    super options, data

    @linked    = no
    {provider} = @getData()

    mainController = KD.getSingleton "mainController"
    mainController.on "ForeignAuthSuccess.#{provider}", =>
      @linked = yes
      @render()


  click:(event)->

    KD.utils.stopDOMEvent event
    if $(event.target).is "a.delete-icon" then @unlink()
    else if $(event.target).is "a.link"   then @link()


  render:->

    super

    @setLinkedState()


  setLinkedState:->

    if @linked
    then @setClass "linked"
    else @unsetClass "linked"


  link:->

    {provider} = @getData()
    KD.singletons.oauthController.openPopup provider


  unlink:->

    {title, provider} = @getData()
    account           = KD.whoami()
    account.unlinkOauth provider, (err)=>
      return KD.showError err  if err
      account.unstore "ext|profile|#{provider}", (err, storage)->
        return warn err  if err

      notify "Your #{title} account is now unlinked."
      @linked = no
      @render()


  viewAppended:->

    JView::viewAppended.call this
    {provider} = @getData()
    @setClass provider
    KD.remote.api.JUser.fetchUser (err, user)=>
      @linked = user.foreignAuth?[provider]?
      @render()


  getLinkedString:-> if @linked then "Linked" else "Not linked."


  getLinkingString:-> if @linked then "" else "Link now."


  pistachio:->

    """
    <div class='title'>
      <span class='icon'></span>{cite{ #(title)}}
      <a href='#' class='delete-icon'></a>
    </div>
    <div class='status'>
      <span class='icon-check'></span>
      {span{ @getLinkedString #(provider)}}
      {a.link[href=#]{ @getLinkingString #(provider)}}
    </div>
    """
