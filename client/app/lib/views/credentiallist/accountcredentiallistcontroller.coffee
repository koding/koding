_                           = require 'lodash'
kd                          = require 'kd'
hljs                        = require 'highlight.js'

KDView                      = kd.View
KDButtonView                = kd.ButtonView
KDContextMenu               = kd.ContextMenu
KDCustomScrollView          = kd.CustomScrollView
KDNotificationView          = kd.NotificationView
KDFormViewWithFields        = kd.FormViewWithFields

KodingSwitch                = require 'app/commonviews/kodingswitch'
MemberAutoCompleteItemView  = require 'app/commonviews/memberautocompleteitemview'
MemberAutoCompletedItemView = require 'app/commonviews/memberautocompleteditemview'

KodingListController        = require 'app/kodinglist/kodinglistcontroller'

remote                      = require('app/remote').getInstance()
globals                     = require 'globals'
showError                   = require 'app/util/showError'
Tracker                     = require 'app/util/tracker'


module.exports = class AccountCredentialListController extends KodingListController


  constructor: (options = {}, data) ->

    options.limit            or= 30
    options.noItemFoundText   ?= "You don't have any credentials"
    options.model             ?= remote.api.JCredential

    super options, data


  bindEvents: ->

    super

    { provider } = @getOptions()
    listView     = @getListView()

    listView.on 'ItemDeleted', @bound 'showNoItemWidget'

    listView.on 'ItemAction', ({ action, item, options }) =>

      credential    = item.getData()
      { provider }  = credential

      switch action

        when 'ShowItem'
          @fetchCredentialData credential, (err, data) ->
            return  if showError err

            { meta }        = data
            meta            = helper.prepareCredentialMeta meta
            meta.identifier = credential.identifier

            cred = JSON.stringify meta, null, 2
            cred = hljs.highlight('json', cred).value

            listView.showCredential { credential, cred }

        when 'EditItem'
          @fetchCredentialData credential, (err, data) ->
            return  if showError err

            Tracker.track Tracker.USER_EDIT_CREDENTIALS

            data.meta  = helper.prepareCredentialMeta data.meta
            data.title = credential.title

            listView.showCredentialEditModal { provider, credential, data }


    @once 'FetchProcessSucceeded', (params) ->
      { items } = params
      if provider and items?.length is 0
        @showAddCredentialFormFor provider


  # Override parent method and show different confirm modal.
  removeItem: (item, options = {}) ->

    listView    = @getListView()
    credential  = item.getData()

    if credential.inuse
      new kd.NotificationView { title: 'This credential is currently in-use' }
      return

    credential.isBootstrapped (err, bootstrapped) =>

      kd.warn 'Bootstrap check failed:', { credential, err }  if err

      listView.askForConfirm { credential, bootstrapped }, ({ action, modal }) =>

        switch action

          when 'Remove'
            @removeCredential item, -> modal.destroy()

          when 'DestroyAll'
            @destroyResources credential, (err) =>
              if err
                modal['button_DestroyAll'].hideLoader()
                modal['button_Remove'].hideLoader()
                modal.destroy()
              else
                @removeCredential item, -> modal.destroy()


  removeCredential: (item, callback) ->

    credential = item.getData()
    listView   = @getListView()

    credential.delete (err) ->
      listView.emit 'ItemDeleted', item  unless showError err
      Tracker.track Tracker.USER_DELETE_CREDENTIALS

      { computeController } = kd.singletons
      computeController.emit 'CredentialRemoved', credential  unless err

      callback err


  destroyResources: (credential, callback) ->

    identifiers = [ credential.identifier ]

    kd.singletons.computeController.getKloud()
      .bootstrap { identifiers, destroy: yes }
      .then -> callback null
      .catch (err) ->
        kd.singletons.computeController.ui.showComputeError
          title   : 'An error occurred while destroying resources'
          message : "
            Some errors occurred while destroying resources that are created
            with this credential.
            <br/>
            You can either visit
            <a href='http://console.aws.amazon.com/' target=_blank>
            console.aws.amazon.com
            </a> to clear the EC2 instances and try this again, or go ahead
            and delete this credential here but you will need to destroy your
            resources manually from AWS console later.
          "
          errorMessage : err?.message ? err

        callback err


  loadItems: ->

    { query, provider, requiredFields } = @getOptions()

    @filterStates.query.provider ?= provider  if provider

    if requiredFields
      @filterStates.query.fields ?= requiredFields.map (field) -> field.name ? field

    super


  fetchCredentialData: (credential, callback) ->

    credential.fetchData (err, data) -> callback err, data


  filterByProvider: (query = {}) ->

    @filterStates.skip  = 0
    @filterStates.query = query

    @removeAllItems()
    @showLazyLoader no

    @fetch @filterStates.query, (credentials) =>
      unless credentials?.length
        @showNoItemWidget()
        return

      @addListItems credentials


  loadView: (mainView) ->

    super mainView

    { provider, requiredFields, dontShowCredentialMenu } = @getOptions()

    if provider
      @createAddDataButton()
    else
      @createAddCredentialMenu()  unless dontShowCredentialMenu


  createAddDataButton: ->

    @getView().parent.prepend addButton = new KDButtonView
      cssClass  : 'add-big-btn'
      title     : 'Create New'
      icon      : yes
      callback  : @lazyBound 'showAddCredentialFormFor', @getOption 'provider'


  createAddCredentialMenu: ->

    Providers    = globals.config.providers
    providerList = {}

    Object.keys(Providers).forEach (provider) =>

      return  if provider is 'custom'
      return  if Object.keys(Providers[provider].credentialFields).length is 0

      providerList[Providers[provider].title] =
        callback : =>
          @_addButtonMenu.destroy()
          @showAddCredentialFormFor provider

    @getView().parent.prepend addButton = new KDButtonView
      cssClass  : 'add-big-btn'
      title     : 'Add new credentials'
      icon      : yes
      callback  : =>
        @_addButtonMenu = new KDContextMenu
          delegate    : addButton
          y           : addButton.getY() + 35
          x           : addButton.getX() + addButton.getWidth() / 2 - 120
          width       : 240
        , providerList

        @_addButtonMenu.setCss { 'z-index': 10002 }


  helper =

    prepareCredentialMeta: (meta) ->

      delete meta.__rawContent
      return _.mapValues meta, (val) -> _.unescape val


  showAddCredentialFormFor: (provider) ->

    { requiredFields, defaultTitle } = @getOptions()

    listView = @getListView()

    view = @getView().parent
    view.form?.destroy()
    view.intro?.destroy()
    view.scrollView?.destroy()

    view.setClass 'form-open'
    @isAddCredentialFormOpen = yes

    view.scrollView = new KDCustomScrollView { cssClass : 'add-credential-scroll' }

    options                 = { provider }
    options.defaultTitle    = defaultTitle    if defaultTitle?
    options.requiredFields  = requiredFields  if requiredFields?

    if provider is 'aws'
      view.scrollView.wrapper.addSubView view.intro = new kd.CustomHTMLView
        cssClass  : 'credential-creation-intro'
        partial   : '''
          <p>Add your AWS credentials</a>
          <ol>
            <li>Create an AWS user</li>
            <li>Attach the AdministratorAccess policy</li>
            <li>Add the Access Key ID and Secret here</li>
          </ol>
          <p>Need some help? <a href='https://koding.com/docs/creating-an-aws-stack'>Follow our guide</a>
          '''

    { computeController } = kd.singletons

    noCredFound = not listView.items.length

    view.form = computeController.ui.generateAddCredentialFormFor options, noCredFound
    view.form.setClass 'credentials-form-view'

    view.form.on 'Cancel', =>
      view.unsetClass 'form-open'
      @isAddCredentialFormOpen = no
      view.scrollView?.destroy()
      view.form.destroy()

    view.form.on 'CredentialAdded', (credential, noCredFound = no) =>
      view.unsetClass 'form-open'
      @isAddCredentialFormOpen  = no
      credential.owner = yes
      view.scrollView?.destroy()
      view.form.destroy()

      if noCredFound
      then @addItem(credential).verifyCredential()
      else
        @addItem credential

      computeController.emit 'CredentialAdded', credential


    # Notify all registered listeners because we need to re-calculate width / height of the KDCustomScroll which in Credentials tab.
    # The KDCustomScroll was hidden while Stacks screen is rendering.
    view.on 'NotifyResizeListeners', -> kd.singletons.windowController.notifyWindowResizeListeners()

    view.scrollView.wrapper.addSubView view.form
    view.addSubView view.scrollView
