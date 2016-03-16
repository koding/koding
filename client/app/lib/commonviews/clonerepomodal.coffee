kd = require 'kd'
KDHitEnterInputView = kd.HitEnterInputView
ModalViewWithTerminal = require './modalviewwithterminal'
FSHelper = require 'app/util/fs/fshelper'


module.exports = class CloneRepoModal extends ModalViewWithTerminal

  constructor: (options = {}, data) ->

    options.title      = 'Clone Remote Repository'
    options.cssClass   = 'modal-with-text clone-repo-modal'
    options.content    = '<p>Enter the URL of remote Git repository to clone.</p>'
    options.overlay    = yes
    options.width      = 500
    options.terminal   =
      hidden           : yes
      vmName           : options.vmName
      height           : 300
    options.buttons    =
      Clone            :
        title          : 'Clone'
        cssClass       : 'solid green medium'
        loader         :
          color        : '#FFFFFF'
          diameter     : 14
        callback       : => @cloneRepo()  if @repoPath.validate()
      Cancel           :
        title          : 'Cancel'
        cssClass       : 'solid light-gray medium'
        callback       : => @destroy()

    super options, data

  viewAppended: ->
    @addSubView @repoPath = new KDHitEnterInputView
      type             : 'text'
      placeholder      : 'Type a git repository URL...'
      validationNotifications: yes
      validate         :
        rules          :
          required     : yes
        messages       :
          required     : 'Please enter a repo URL.'
      callback         : @bound 'cloneRepo'

  cloneRepo: ->
    return if @cloning
    @buttons.Clone.showLoader()

    command  = """
      cd #{FSHelper.plainPath @getOptions().path} ; git clone #{@repoPath.getValue()}; echo -e "\\e]1;$?;$(date +%s%N)\\e\\\\"
    """

    @cloning = yes
    @setClass 'running'
    @run command

    @once 'terminal.event', (data) ->
      if data is '0'
        @destroy()
        @emit 'RepoClonedSuccessfully'
