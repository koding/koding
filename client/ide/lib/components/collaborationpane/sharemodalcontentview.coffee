kd        = require 'kd'
ReactView = require 'app/react/reactview'
React     = require 'kd-react'

class ShareModalContent extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'ShareModalContent', options.cssClass
    super options, data


  selectToCopy: ->

    copyEl = document.querySelectorAll('.ShareLink-tooltip > div > span')[0]
    kd.utils.selectText copyEl

    try
      copied = document.execCommand 'copy'
      throw 'couldn\'t copy'  unless copied
    catch
      hintEl = document.querySelectorAll('.ShareLink-tooltip > div > i')[0]
      key    = if globals.os is 'mac' then 'Cmd + C' else 'Ctrl + C'

      hintEl.innerHTML = "Hit #{key} to copy!"


  renderReact: ->

    <div ref={@bound 'selectToCopy'} className='ShareLink-tooltip'>
      <div>
        <i>Copied to clipboard</i>
        <span>{@options.url}</span>
      </div>
    </div>


