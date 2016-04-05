kd    = require 'kd'
JView = require 'app/jview'
nick  = require 'app/util/nick'

ActivityAutoCompleteUserItemView         = require 'activity/views/activityautocompleteuseritemview'
ChatHead                                 = require 'activity/views/chathead'
FetchingActivityAutoCompleteUserItemView = require 'activity/views/fetchingactivityautocompleteuseritemview'

module.exports = class ResourceSearchView extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'search', options.cssClass
    super options, data

    @searchInput = new kd.HitEnterInputView
      type        : 'text'
      placeholder : 'Search in resources...'
      callback    : @bound 'doSimpleSearch'

    @searchClear = new kd.CustomHTMLView
      tagName     : 'span'
      partial     : 'clear'
      cssClass    : 'clear-search hidden'
      click       : @bound 'clearSimpleSearch'

    @advancedModeLink = new kd.CustomHTMLView
      tagName     : 'span'
      partial     : 'advanced search'
      cssClass    : 'advanced-search-link'
      click       : @bound 'switchToAdvancedMode'

    @createAdvancedForm()


  createAdvancedForm: ->

    @advancedForm   = new kd.FormViewWithFields
      fields        :
        title       :
          label     : 'Title'
        status      :
          label     : 'Status'
          itemClass : kd.SelectBox
        accounts    :
          label     : 'Accounts'
          itemClass : kd.View
        isGroup     :
          label     : 'Is group stack?'
          type      : 'checkbox'
      buttons       :
        search      :
          title     : 'Search'
          type      : 'submit'
          style     : 'solid green medium'
        clear       :
          title     : 'Clear'
          style     : 'solid light-gray medium'
          callback  : @bound 'clearAdvancedSearch'
      callback      : @bound 'doAdvancedSearch'

    { status, accounts } = @advancedForm.inputs
    status.setSelectOptions [
      { title : 'Any',            value : '' }
      { title : 'NotInitialized', value : 'NotInitialized' }
      { title : 'Building',       value : 'Building' }
      { title : 'Initialized',    value : 'Initialized' }
      { title : 'Destroying',     value : 'Destroying' }
    ]

    accountHeads        = new kd.View { cssClass : 'autocomplete-heads' }
    accountAutoComplete = new kd.AutoCompleteController
      form                : @advancedForm
      name                : 'userController'
      placeholder         : 'Type a username...'
      itemClass           : ActivityAutoCompleteUserItemView
      fetchingItemClass   : FetchingActivityAutoCompleteUserItemView
      outputWrapper       : accountHeads
      itemDataPath        : 'profile.nickname'
      listWrapperCssClass : 'private-message'
      outputWrapper       : accountHeads
      selectedItemClass   : ChatHead
      submitValuesAsText  : yes
      dataSource          : @bound 'fetchAccounts'

    accounts.addSubView accountAutoComplete.getView()
    accounts.addSubView accountHeads


  doAdvancedSearch: (data) ->

    dataProps =
      'title'             : 'title'
      'status.state'      : 'status'
      'config.groupStack' : 'isGroup'

    pairs = []
    for prop, field of dataProps when value = data[field]
      value = "'#{value}'"  if typeof value is 'string'
      pairs.push "#{prop}: #{data[field]}"

    query = "{#{pairs.join ','}}"  if pairs.length

    @emitSearch query


  clearAdvancedSearch: ->

    @advancedForm.reset()
    @advancedForm.inputs.status.setValue ''

    @emitSearch()


  doSimpleSearch: ->

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


  clearSimpleSearch: ->

    @lastQuery = null
    @searchInput.setValue ''

    @emitSearch()


  emitSearch: (query) -> @emit 'SearchRequested', query


  switchToAdvancedMode: ->

    @setClass 'advanced-search-mode'


  fetchAccounts: ({ inputValue }, callback) ->

    { search } = kd.singletons
    search.searchAccounts inputValue
      #.filter (it) => it.profile.nickname isnt nick()
      .then callback
      .catch (err) ->
        console.warn 'Error while autoComplete: ', err
        callback []


  pistachio: ->

    """
      <div class='simple-search-container'>
        {{> @searchInput}}
        {{> @searchClear}}
        {{> @advancedModeLink}}
      </div>
      <section class='AppModal-section advanced-search-container'>
        {{> @advancedForm}}
        <div class='clearfix'></div>
      </section>
    """
