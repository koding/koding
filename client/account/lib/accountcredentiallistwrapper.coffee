kd                      = require 'kd'
KDView                  = kd.View
globals                 = require 'globals'
KDSelectBox             = kd.SelectBox
KDLabelView             = kd.LabelView
KDContextMenu           = kd.ContextMenu

AccountCredentialList           = require './accountcredentiallist'
AccountCredentialListController = require './views/accountcredentiallistcontroller'


module.exports = class AccountCredentialListWrapper extends KDView


  constructor: (options = {}, data) ->

    super options, data

    @createFilterView()

    @listController = new AccountCredentialListController
      view                    : new AccountCredentialList
      limit                   : 15
      useCustomScrollView     : yes
      lazyLoadThreshold       : 15
      dontShowCredentialMenu  : yes

    @addSubView @listController.getView()


  createFilterView: ->

    @filterView = new KDView
      cssClass : 'filter-view'

    @filterView.addSubView new KDLabelView
      title : 'Show'

    selectOptions = [
      { title : 'All',        value : ''  } # Firstly set default option
      { title : 'User Input', value : 'userInput' }
    ]

    providers = @getValidProviders()

    for provider in providers

      continue  if provider.key is 'custom' or provider.key is 'koding'

      selectOptions.push
        title : provider.title
        value : provider.key


    @filterView.addSubView selectBox = new KDSelectBox
      selectOptions : selectOptions
      defaultValue  : ''
      callback      : (value) =>
        filter = {}
        filter.provider = value  if value
        @listController.filterByProvider filter

    @addSubView @filterView


  ###*
   * @return {Array} list
  ###
  getValidProviders: ->

    list          = []
    { providers } = globals.config

    Object.keys(providers).forEach (provider) ->

      list.push
        key   : provider
        title : providers[provider].title

    return list

