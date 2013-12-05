class AccountLinkedAccountsListController extends KDListViewController

  constructor:(options = {}, data)->
    super options, data
    @instantiateListItems ({title : nicename, provider} for own provider, {nicename} of KD.config.externalProfiles)

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
    @setClass provider

    @switch = new KodingSwitch
      callback: (state)=>
        @switch.setOff no
        if state then @link() else @unlink()

    mainController = KD.getSingleton "mainController"
    mainController.on "ForeignAuthSuccess.#{provider}", =>
      @linked = yes
      @switch.setOn no

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


  viewAppended:->

    JView::viewAppended.call this
    {provider} = @getData()
    KD.remote.api.JUser.fetchUser (err, user)=>
      @linked = user.foreignAuth?[provider]?
      @switch.setDefaultValue @linked


  pistachio:->

    """
    <div class='title'><span class='icon'></span>{cite{ #(title)}}</div>
    {{> @switch}}
    """
