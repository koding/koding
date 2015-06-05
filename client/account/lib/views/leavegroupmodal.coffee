kd              = require 'kd'
nick            = require 'app/util/nick'
DeleteModalView = require '../deletemodalview'


module.exports = class LeaveGroupModal extends DeleteModalView


  constructor: (options = {}, data) ->

    data = nick()

    options.title       = 'Please confirm group leave action'
    options.buttonTitle = 'Leave Group'
    options.content     = """
      <div class='modalformline'>
        <p>
          <strong>CAUTION! </strong>You will leave your current group and you will not be able to login again. This action <strong>CANNOT</strong> be undone.
        </p>
        <br>
        <p>Please enter <strong>#{data}</strong> into the field below to continue: </p>
      </div>
    """

    super options, data


  doAction: ->

    kd.warn 'Group leave action should be handled...'
