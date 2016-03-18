kd                    = require 'kd'
BaseModalView         = require './views/basemodalview'
HelpSupportModal      = require '../commonviews/helpsupportmodal'
JView                 = require '../jview'


DEFAULT_PERCENTAGE = 10


###*
 * EnvironmentsProgressModal is a simple progressbar with an overlay for
 * the given container.
###
module.exports = class EnvironmentsProgressModal extends BaseModalView

  ###*
   * @param {Number} options.initial - The initial progress value.
   * @param {String} options.actionLabel - Printed as part of the
   *  "machine is Label" and "error during actionLabel" messages.
   * @param {String} options.customErrorMessage - An optional error message
   *  replacing the entire error partial. Use the class `contact-support`
   *  on a span to open the HelpSupportModal
  ###
  constructor: (options = {}, data) ->

    options.cssClass    ?= 'env-machine-state'
    options.width        = 440
    options.initial     ?= 10
    options.actionLabel ?= 'Processing a task'

    super

    @machine     = @getData()
    @machineName = @machine?.jMachine?.label

    @initViews()


  ###*
   * Create error views
  ###
  createErrorViews: ->

    { customErrorMessage, actionLabel } = @getOptions()
    message = new kd.CustomHTMLView
      cssClass    : 'error-message'
      partial     : customErrorMessage or """
        <p>There was an error while #{actionLabel}.</p>
        <span>Please try reloading this page or <span
        class="contact-support">contact support</span> for further
        assistance.</span>
      """
      click: (event) =>
        if 'contact-support' in event.target.classList
          kd.utils.stopDOMEvent event
          new HelpSupportModal
          @destroy()
        else if 'close' in event.target.classList
          @destroy()

    #close = new kd.ButtonView
    #  title    : 'Close'
    #  callback : @bound 'destroy'

    @container.addSubView @errorMessage = new JView
      cssClass        : 'error-container hidden'
      pistachioParams : { message }
      pistachio       : '''
        <div>
          {{> message}}
        </div>
        '''


  ###*
   * Create the label for this machine's progress bar.
  ###
  createActionLabel: ->

    { actionLabel } = @getOptions()
    @container.addSubView @actionLabel = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'state-label'
      partial  : """
        <span class='icon'></span>
        #{actionLabel} for <strong>#{@machineName or 'your vm'}</strong>
      """


  ###*
   * Create the progress bar.
  ###
  createProgressBar: (initial = DEFAULT_PERCENTAGE) ->

    @container.addSubView @progressBar = new kd.ProgressBarView { initial }


  ###*
   * Create the views for this modal.
  ###
  initViews: ->

    @container = new kd.CustomHTMLView { cssClass: 'content-container' }
    @addSubView @container

    @createActionLabel()
    @createProgressBar @getOptions().initial
    @createErrorViews()


  ###*
   * Show the error message.
  ###
  showError: -> @errorMessage.show()


  ###*
   * Update the progress bar's percentage.
   *
   * @param {Number} percentage - The percentage to set the bar to.
  ###
  updatePercentage: (percentage = DEFAULT_PERCENTAGE) ->

    @progressBar.updateBar percentage
