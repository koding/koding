kd = require 'kd'
JView = require 'app/jview'


module.exports = class OnboardingSettingsMenuItem extends JView

  pistachio :->
    {title} = @getData()
    """
      <i class="#{kd.utils.slugify title} icon"></i>#{title}
    """

