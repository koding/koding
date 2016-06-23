kd = require 'kd'
ContentModal = require 'app/components/contentModal'

module.exports = class FilePermissionsModal extends ContentModal

  constructor: (options = {}, data) ->

    options.content ?= """
      <div class="modalformline">
        <p>
          #{options.contentText}
          Read more about permissions <a class="help" href="https://koding.com/docs/understanding-file-permissions" target="_blank">here</a>.
        </p>
      </div>
    """
    options.overlay  = yes
    options.cssClass = 'content-modal'
    options.buttons  =
      ok :
        cssClass : 'solid medium'
        title    : 'OK'
        callback : @bound 'destroy'

    super options, data
