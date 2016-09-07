JView = require 'app/jview'
Encoder = require 'htmlencode'

module.exports = class EmbedBoxObjectView extends JView

  pistachio:->
    objectHtml = @getData().link_embed?.object?.html
    """
    <div class="embed embed-object-view custom-object">
      #{Encoder.htmlDecode objectHtml or ''}
    </div>
    """
