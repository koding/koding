kd             = require 'kd'
KDView         = kd.View
globals        = require 'globals'
KDSelectBox    = kd.SelectBox
KDLabelView    = kd.LabelView
KDContextMenu  = kd.ContextMenu
KDHeaderView   = kd.HeaderView

AccountCredentialList           = require './accountcredentiallist'
AccountCredentialListController = require './views/accountcredentiallistcontroller'


module.exports = class AccountCredentialListWrapper extends KDView


  DEFAULT_LIST_TEXT = """
    List of additional credentials for your account. These are includes generic
    data for using with 3rd party integrations on your stacks.
  """

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @top = new KDView
      cssClass : 'top'

    @top.addSubView @header = new KDHeaderView
      title : DEFAULT_LIST_TEXT

    @createFilterView()

    @listController = new AccountCredentialListController
      view                    : new AccountCredentialList
      limit                   : 15
      useCustomScrollView     : yes
      lazyLoadThreshold       : 15
      dontShowCredentialMenu  : yes

    @addSubView @listController.getView()


  createFilterView: ->

    @top.addSubView @filterView = new KDView
      cssClass : 'filter-view'

    @filterView.addSubView new KDLabelView
      title : 'Show'

    selectOptions = [
      { title : 'All', value : '' } # Firstly set default option
    ]

    providers = @getValidProviders()

    for provider in providers

      continue  if provider.key is 'managed' or provider.key is 'koding'

      selectOptions.push
        title : provider.title
        value : provider.key


    @filterView.addSubView selectBox = new KDSelectBox
      selectOptions : selectOptions
      defaultValue  : ''
      callback      : @bound 'doFilter'


  ###*
   * @return {Array} list
  ###
  getValidProviders: ->

    list          = []
    { providers } = globals.config

    Object.keys(providers).forEach (provider) ->

      list.push
        key      : provider
        title    : providers[provider].title

    return list


  doFilter: (value) ->

    { providers } = globals.config

    filter = {}
    filter.provider = value  if value
    @listController.filterByProvider filter

    if provider = providers[value]
      { listText } = provider

    listText = DEFAULT_LIST_TEXT unless listText

    @header.updateTitle listText
