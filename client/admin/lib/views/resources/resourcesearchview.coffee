kd    = require 'kd'
JView = require 'app/jview'
nick  = require 'app/util/nick'

ResourceSearchAccountsView = require './resourcesearchaccountsview'

module.exports = class ResourceSearchView extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'search', options.cssClass
    super options, data

    @searchInput = new kd.HitEnterInputView
      type        : 'text'
      placeholder : 'Search in resources...'
      callback    : @bound 'doRegularSearch'

    @searchClear = new kd.CustomHTMLView
      tagName     : 'span'
      partial     : 'clear'
      cssClass    : 'clear-search hidden'
      click       : @bound 'clearRegularSearch'

    @advancedModeLink = new kd.CustomHTMLView
      tagName     : 'span'
      partial     : 'advanced search'
      cssClass    : 'advanced-search-link'
      click       : @bound 'switchToAdvancedMode'

    @createAdvancedForm()


  createAdvancedForm: ->

    @advancedForm     = new kd.FormViewWithFields
      fields          :
        title         :
          label       : 'Title'
          placeholder : 'Type a title...'
        status        :
          label       : 'Status'
          itemClass   : kd.SelectBox
        type          :
          label       : 'Stack template type'
          itemClass   : kd.SelectBox
        accounts      :
          label       : 'Accounts'
          itemClass   : ResourceSearchAccountsView
      buttons         :
        search        :
          title       : 'Search'
          type        : 'submit'
          style       : 'solid green medium'
        clear         :
          title       : 'Clear'
          style       : 'solid medium'
          callback    : @bound 'clearAdvancedSearch'
        cancel        :
          title       : 'Cancel'
          style       : 'solid light-gray medium'
          callback    : @bound 'switchToRegularMode'
      callback        : @bound 'doAdvancedSearch'

    { status, type, accounts } = @advancedForm.inputs

    status.setSelectOptions [
      { title : 'Any',            value : '' }
      { title : 'NotInitialized', value : 'status.state: NotInitialized' }
      { title : 'Building',       value : 'status.state: Building' }
      { title : 'Initialized',    value : 'status.state: Initialized' }
      { title : 'Destroying',     value : 'status.state: Destroying' }
    ]

    type.setSelectOptions [
      { title : 'Any',     value : '' }
      { title : 'Group',   value : 'config.groupStack: true' }
      { title : 'Private', value : 'config.groupStack: false' }
    ]

    accounts.setForm @advancedForm


  doAdvancedSearch: (data) ->

    dataFormats =
      title     : (value) -> "searchFor: '#{value}'"
      accounts  : (value) ->
        return  unless value.length
        accountIds = value.map (item) -> item.id
        return "originId: { $in: [#{accountIds.join ','}] }"

    conditions = []
    for name, value of data when value
      value = dataFormat value  if dataFormat = dataFormats[name]
      conditions.push value

    query = "{#{conditions.join ','}}"  if conditions.length

    @emitSearch query


  clearAdvancedSearch: ->

    @advancedForm.reset()

    { status, type, accounts } = @advancedForm.inputs
    status.setValue ''
    type.setValue ''
    accounts.reset()

    @emitSearch()


  doRegularSearch: ->

    query          = @searchInput.getValue()
    isQueryEmpty   = query is ''
    isQueryChanged = query isnt @lastQuery

    if isQueryEmpty
      @searchClear.hide()
      return @emitSearch()

    return  unless isQueryChanged

    @lastQuery = query
    @searchClear.show()
    @emitSearch query


  clearRegularSearch: (skipEvent) ->

    @lastQuery = null
    @searchInput.setValue ''

    @emitSearch()  unless skipEvent


  emitSearch: (query) -> @emit 'SearchRequested', query


  switchToAdvancedMode: ->

    @emit 'AdvancedSearchMode'


  switchToRegularMode: ->

    @clearRegularSearch yes
    @clearAdvancedSearch()
    @emit 'RegularSearchMode'


  pistachio: ->

    """
      <div class='regular-search-container'>
        {{> @searchInput}}
        {{> @searchClear}}
        {{> @advancedModeLink}}
      </div>
      <section class='AppModal-section advanced-search-container'>
        {{> @advancedForm}}
        <div class='clearfix'></div>
      </section>
    """
