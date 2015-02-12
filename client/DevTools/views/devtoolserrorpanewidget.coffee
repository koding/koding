class DevToolsErrorPaneWidget extends JView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'error-pane', options.cssClass
    super options, data

  pistachio:->
    {error} = @getData()
    line    = if error.location then "at line: #{error.location.last_line+1}" else ""
    stack   = if error.stack? then """
      <div class='stack'>
        <h2>Full Stack</h2>
        <pre>#{error.stack}</pre>
      </div>
    """ else ""

    """
      {h1{#(error.name)}}
      <pre>#{error.message} #{line}</pre>
      #{stack}
    """

  click:-> @setClass 'in'
