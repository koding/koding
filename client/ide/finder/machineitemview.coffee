class MachineItemView extends NFileItemView


  constructor: (options = {}, data) ->

    options.cssClass or= "vm"

    super options, data

    {@machine}   = @getData()
    plainPath    = FSHelper.plainPath @getData().path
    nickWithRoot = "/home/#{KD.nick()}"

    if plainPath isnt nickWithRoot
      plainPath  = plainPath.replace nickWithRoot, "~"

    @machineInfo = new KDCustomHTMLView
      tagName    : 'span'
      cssClass   : 'vm-info'
      partial    : plainPath


  pistachio:->
    return """
      <div class="vm-header">
        {{> @machineInfo}}
        <div class="buttons">
          <span class='chevron'></span>
        </div>
      </div>
    """


module.exports = MachineItemView
