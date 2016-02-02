kd = require 'kd'
KDModalView = kd.ModalView

module.exports = class FilePermissionsModal extends KDModalView

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
    options.cssClass = 'file-permissions-modal'
    options.buttons  =
      ok :
        cssClass : 'solid green medium'
        title    : 'OK'
        callback : @bound 'destroy'

    super options, data
