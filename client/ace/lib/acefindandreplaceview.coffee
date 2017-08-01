kd                  = require 'kd'
KDButtonView        = kd.ButtonView
KDCustomHTMLView    = kd.CustomHTMLView
KDHitEnterInputView = kd.HitEnterInputView
KDMultipleChoice    = kd.MultipleChoice

$                   = require 'jquery'
keycode             = require 'keycode'

module.exports = class AceFindAndReplaceView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass = 'search-view'

    super options, data

    @mode = null

    @createElements()


  handleKeyDown: (isFind, e) ->

    code = e.which or e.keyCode
    key  = keycode code

    switch key
      when 'esc' then @close()
      when 'enter'
        @findPrev()  if isFind and e.shiftKey is yes
      when 'f'
        if e.metaKey
          e.preventDefault()
          @show yes
    return


  close: (fireEvent = yes) ->

    $(window).off 'keydown.acefindview'

    @hide()
    @findInput.setValue    ''
    @replaceInput.setValue ''
    @emit 'FindAndReplaceViewClosed'  if fireEvent


  show: (withReplace) ->

    super

    $(window).on 'keydown.acefindview', (event) =>
      @close()  if event.which is 27

    cssName = 'with-replace-view'
    method  = if withReplace then 'setClass' else 'unsetClass'

    @[method] cssName
    @emit 'FindAndReplaceViewShown', withReplace


  setTextIntoFindInput: (text) ->

    return @findInput.setFocus() if text.indexOf('\n') > 0 or text.length is 0

    @findInput.setValue text
    @findInput.setFocus()


  getSearchOptions: ->

    @selections   = @choices.getValue()

    caseSensitive : @selections.indexOf('case-sensitive') > -1
    wholeWord     : @selections.indexOf('whole-word') > -1
    regExp        : @selections.indexOf('regex') > -1
    backwards     : no


  findNext: -> @findHelper 'next'


  findPrev: -> @findHelper 'prev'


  findHelper: (direction) ->

    keyword = @findInput.getValue()

    return unless keyword

    methodName = if direction is 'prev' then 'findPrevious' else 'find'
    @getDelegate().ace.editor[methodName] @findInput.getValue(), @getSearchOptions()
    @findInput.focus()
    @highlight()


  highlight: ->

    { editor } = @getDelegate().ace
    editor.session.highlight editor.$search.$options.re
    editor.renderer.updateBackMarkers()


  replace:    -> @replaceHelper no


  replaceAll: -> @replaceHelper yes


  replaceHelper: (doReplaceAll) ->

    findKeyword    = @findInput.getValue()
    replaceKeyword = @replaceInput.getValue()

    return unless findKeyword or replaceKeyword

    { editor } = @getDelegate().ace
    methodName = if doReplaceAll then 'replaceAll' else 'replace'

    editor[methodName] replaceKeyword

    @findNext()


  createElements: ->

    @findInput = new KDHitEnterInputView
      type         : 'text'
      cssClass     : 'search-input-with-icon'
      placeholder  : 'Find in the file…'
      validate     :
        rules      :
          required : yes
      keydown      : (e) => @handleKeyDown yes, e
      callback     : => @findNext()

    @findNextButton = new KDButtonView
      cssClass     : 'find-button find-next'
      callback     : => @findNext()

    @findPrevButton = new KDButtonView
      cssClass     : 'find-button find-prev'
      callback     : => @findPrev()

    @replaceInput = new KDHitEnterInputView
      type         : 'text'
      cssClass     : 'search-input'
      placeholder  : 'Replace with…'
      validate     :
        rules      :
          required : yes
      keydown      : (e) => @handleKeyDown no, e
      callback     : => @replace()

    @replaceButton = new KDButtonView
      title        : 'Replace'
      cssClass     : 'search-button search-button-replace'
      callback     : => @replace()

    @replaceAllButton = new KDButtonView
      title        : 'Replace All'
      cssClass     : 'search-button search-button-replace'
      callback     : => @replaceAll()

    @closeButton = new KDCustomHTMLView
      tagName      : 'span'
      cssClass     : 'close-icon'
      click        : => @close()

    @choices = new KDMultipleChoice
      cssClass     : ''
      labels       : ['case-sensitive', 'whole-word', 'regex']
      multiple     : yes
      defaultValue : 'fakeValueToDeselectFirstOne'


  pistachio: ->
    return '''
      <div class="search-options-button-group">
        {{> @choices}}
      </div>
      <div class="search-inputs">
        <div class="search-input-wrapper search-input-group">
          {{> @findInput}}
          {{> @findNextButton}}
          {{> @findPrevButton}}
        </div>
        <div class="search-input-wrapper search-replace-wrapper">
          {{> @replaceInput}}
        </div>
        <div class="search-buttons search-button-group search-replace-button-group">
          {{> @replaceButton}}
          {{> @replaceAllButton}}
        </div>
      </div>
      <div class="search-view-close-wrapper">
        {{> @closeButton}}
      </div>
    '''
