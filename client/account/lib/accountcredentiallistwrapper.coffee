kd                      = require 'kd'
KDView                  = kd.View
globals                 = require 'globals'
KDSelectBox             = kd.SelectBox
KDLabelView             = kd.LabelView
KDContextMenu           = kd.ContextMenu
KDCustumScrollView      = kd.CustomScrollView

AccountCredentialList           = require './accountcredentiallist'
AccountCredentialListController = require './views/accountcredentiallistcontroller'


module.exports = class AccountCredentialListWrapper extends KDView


  constructor: (options = {}, data) ->

    super options, data

    @createFilterView()

    @addSubView @scrollView = new KDCustumScrollView

    @scrollView.wrapper.addSubView @listView = new AccountCredentialList
      delegate    : @getDelegate()

    @listController = new AccountCredentialListController
      view                    : @listView
      wrapper                 : no
      scrollView              : no
      dontShowCredentialMenu  : yes


  createFilterView: ->

    @filterView = new KDView
      cssClass : 'filter-view'

    @filterView.addSubView new KDLabelView
      title : 'Filter by provider type'

    selectOptions = [
      { title : 'All',  value : ''  } # Firstly set default option
    ]

    providers = @getValidProviders()

    for provider in providers

      selectOptions.push
        title : provider.title
        value : provider.key


    @filterView.addSubView selectBox = new KDSelectBox
      selectOptions : selectOptions
      defaultValue  : ''
      callback      : (value) =>
        @listController.filterByProvider value

    @addSubView @filterView


  ###*
   * @return {Array} list
  ###
  getValidProviders: ->

    list          = []
    { providers } = globals.config

    Object.keys(providers).forEach (provider) =>

      list.push
        key   : provider
        title : providers[provider].title

    return list

