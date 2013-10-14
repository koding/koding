class ODeskWidget extends JView

  constructor:(options = {}, data)->

    options.cssClass = 'odesk-widget'

    super options, data

    @label = new KDLabelView
      title        : 'Post this as a job on <a href="http://odesk.com" target="_blank">oDesk</a>'
      for          : 'odesk-job'

    @checkbox = new KDInputView
      type         : 'checkbox'
      defaultValue : off
      label        : @label
      name         : 'odesk-job'


  pistachio:->
    """
    {{> @checkbox}}{{> @label}}
    """



