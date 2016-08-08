kd = require 'kd'
JView = require 'app/jview'
IDETailerPane = require 'ide/workspace/panes/idetailerpane'

module.exports = class BuildStackLogsPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @startCodingButton = new kd.ButtonView
      title    : 'Start Coding'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'

    @logsContainer = new kd.CustomHTMLView { cssClass : 'logs-pane' }
    @render()


  render: ->

    { tailOffset } = @getOptions()
    { file } = @getData()

    @logsContainer.destroySubViews()
    return  unless file

    logsPane = new IDETailerPane {
      file
      tailOffset
      delegate : this
    }
    @logsContainer.addSubView logsPane


  pistachio: ->

    '''
      <div class="build-stack-logs-page">
        <section class="main">
          {{> @logsContainer}}
        </section>
        <footer>
          {{> @startCodingButton}}
        </footer>
      </div>
    '''
