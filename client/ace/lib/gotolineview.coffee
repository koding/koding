kd                          = require 'kd'
KDButtonView                = kd.ButtonView
KDCustomHTMLView            = kd.CustomHTMLView
KDHitEnterInputView         = kd.HitEnterInputView
JView                       = require 'app/jview'
_                           = require 'lodash'
keycode                     = require 'keycode'

module.exports = class GotoLineView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'search-view goto-line-view'

    super options, data

    @callback = options.callback
    @createElements()


  handleKeyDown: (e) ->

    key = keycode e.which or e.keyCode

    return @destroy()  if key is 'esc'


  destroy: ->

    uber = JView::destroy.bind this
    @lineInput.setValue    ''
    uber()
    @emit 'KDObjectWillBeDestroyed', this


  gotoLine: ->

    line = parseInt @lineInput.getValue(), 10
    @callback line


  createElements: ->

    @lineInput = new KDHitEnterInputView
      type         : 'text'
      cssClass     : 'search-input'
      placeholder  : 'Enter a line number...'
      validate     :
        rules      :
          required : yes
      keydown      : _.bind @handleKeyDown, this
      callback     : @bound 'gotoLine'

    @goButton = new KDButtonView
      title        : 'Go'
      cssClass     : 'search-button'
      callback     : @bound 'gotoLine'

    @closeButton = new KDCustomHTMLView
      tagName      : 'span'
      cssClass     : 'close-icon'
      click        : @bound 'destroy'


  viewAppended: ->

    super
    @lineInput.setFocus()


  pistachio: ->

    return '''
      <div class="goto-line-wrapper">
        <div class="search-inputs">
          <div class="search-input-wrapper">
            {{> @lineInput}}
          </div>
          <div class="search-buttons">
            {{> @goButton}}
          </div>
        </div>
        <div class="search-view-close-wrapper">
          {{> @closeButton}}
        </div>
      </div>
    '''
