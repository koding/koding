kd             = require 'kd'
KDView         = kd.View
globals        = require 'globals'
KDSelectBox    = kd.SelectBox
KDLabelView    = kd.LabelView
KDHeaderView   = kd.HeaderView

AccountCredentialList           = require 'app/views/credentiallist/accountcredentiallist'
AccountCredentialListController = require 'app/views/credentiallist/accountcredentiallistcontroller'


module.exports = class HomeAccountCredentialsView extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @top = new kd.CustomHTMLView
      cssClass : 'top'

    @createFilterView()

    @listController = new AccountCredentialListController
      view                : new AccountCredentialList
      limit               : 15
      wrapper             : no
      scrollView          : no
      useCustomScrollView : no

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

      continue  if provider.key is 'managed'

      selectOptions.push
        title : provider.title
        value : provider.key


    @filterView.addSubView new KDSelectBox
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
