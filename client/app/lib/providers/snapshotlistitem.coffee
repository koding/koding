kd                        = require 'kd'
remote                    = require('app/remote').getInstance()
JView                     = require '../jview'
nicetime                  = require '../util/nicetime'



module.exports = class SnapshotListItem extends kd.ListItemView

  constructor: (options = {}, data) ->

    options.type = 'snapshot'

    options.cssClass = kd.utils.curry options.cssClass, 'snapshot'

    super options, data

    @initViews()
    @setLabel data.label


  ###*
   * Display a simple Notification to the user.
  ###
  @notify: (msg = '') ->

    new kd.NotificationView { content: msg }


  ###*
   * Return a nicely formatted created at.
  ###
  @prettyCreatedAt: (createdAt) ->

    createdAt = new Date(createdAt) if typeof createdAt is 'string'
    createdAtAgo = nicetime (createdAt - Date.now()) / 1000

    return createdAtAgo


  ###*
   * Create all of the subviews.
  ###
  initViews: ->

    data = @getData()
    @editInput = new kd.HitEnterInputView
      type        : 'text'
      placeholder : 'Snapshot Name'
      cssClass    : 'label'
      callback    : @bound 'renameSnapshot'

    @editRenameBtn = new kd.ButtonView
      title    : 'rename'
      cssClass : 'solid green small rename'
      callback : @bound 'renameSnapshot'

    @editCancelBtn = new kd.View
      partial  : 'cancel'
      tagName  : 'span'
      cssClass : 'cancel'
      click    : @bound 'toggleEditable'

    @labelView = new kd.View
      tagName  : 'span'
      cssClass : 'label column'
      click    : @bound 'toggleEditable'

    @infoRenameBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'rename'
      callback : @bound 'toggleEditable'
      tooltip  :
        title  : 'Rename Snapshot'

    @infoDeleteBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'delete'
      callback : @bound 'confirmDeleteSnapshot'
      tooltip  :
        title  : 'Delete Snapshot'

    @infoNewVmBtn = new kd.ButtonView
      iconOnly : true
      cssClass : 'new-vm'
      callback : @bound 'vmFromSnapshot'
      tooltip  :
        title  : 'Create VM from Snapshot'

    @addSubView @editView = new JView
      cssClass        : 'edit hidden'
      pistachioParams : { @editInput, @editRenameBtn, @editCancelBtn }
      pistachio       : '''
        {{> editInput}}
        <div class="buttons">
          {{> editCancelBtn}}
          {{> editRenameBtn}}
        </div>
        '''

    @addSubView @infoView = new JView
      cssClass        : 'info'
      pistachioParams : { @labelView, @infoRenameBtn, @infoDeleteBtn,
        @infoNewVmBtn }
      pistachio       : """
        {{> labelView}}
        <span class="column created-at">#{SnapshotListItem.prettyCreatedAt data.createdAt}</span>
        <span class="column size">#{data.storageSize}GB</span>
        <div class="buttons">
          {{> infoRenameBtn}}
          {{> infoDeleteBtn}}
          {{> infoNewVmBtn}}
        </div>
        """


  partial: ->


  ###*
   * Set the value of the label (name) UI element.
   *
   * @param {String} label - The label (name) to set.
  ###
  setLabel: (label) ->

    @labelView.updatePartial label
    @labelView.setClass kd.utils.slugify label
    @editInput.setValue label


  ###*
   * Toggle (swap) the visibility of @infoView and @editView
  ###
  toggleEditable: ->

    if not @infoView.hasClass 'hidden'
      @infoView.hide()
      @editView.show()
      kd.utils.defer @editInput.bound 'setFocus'
    else
      @infoView.show()
      @editView.hide()
