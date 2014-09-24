class SearchInputView extends KDHitEnterInputView

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "search-input", options.cssClass
    options.placeholder ?= "Search"
    options.type ?= 'input'
    options.stayFocused ?= yes

    super options, data

    @on "EnterPerformed", => @emit "SearchRequested", @getValue()

  clear: ->
    @setValue ""
    super()
