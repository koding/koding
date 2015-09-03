kd             = require 'kd'
JView          = require 'app/jview'
CustomLinkView = require 'app/customlinkview'


module.exports = class StackEditorFooterView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-editor-footer'

    super options, data

    @inviteLink = new CustomLinkView
      title: 'Invite a teammate'
      click: -> kd.singletons.router.handleRoute '/Admin/Invitations'

  pistachio: ->

    return """
      <div class="section">
        <span class="icon"></span>
        <div class="text">
          <p>Need some help?</p>
          {{> @inviteLink}}
        </div>
      </div>
      <div class="section">
        <span class="icon"></span>
        <div class="text">
          <p>To learn about stack files</p>
          <a href="#">Check out our docs</a>
        </div>
      </div>
    """
