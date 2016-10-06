kd = require 'kd'

module.exports = headerize = (title) ->

  domId  = kd.utils.slugify title
  header = new kd.CustomHTMLView
    tagName  : 'header'
    cssClass : 'HomeAppView--sectionHeader'
    domId    : domId
    partial  : """
      <a href="##{domId}">
        <svg class="anchor" aria-hidden="true" height="16" version="1.1" viewBox="0 0 16 16" width="16">
          <path fill="#9f9f9f" d="M12 4h-2.156c0.75 0.5 1.453 1.391 1.672 2h0.469c1.016 0 2 1 2 2s-1.016 2-2 2h-3c-0.984 0-2-1-2-2 0-0.359 0.109-0.703 0.281-1h-2.141c-0.078 0.328-0.125 0.656-0.125 1 0 2 1.984 4 3.984 4s1.016 0 3.016 0 4-2 4-4-2-4-4-4zM4.484 10h-0.469c-1.016 0-2-1-2-2s1.016-2 2-2h3c0.984 0 2 1 2 2 0 0.359-0.109 0.703-0.281 1h2.141c0.078-0.328 0.125-0.656 0.125-1 0-2-1.984-4-3.984-4s-1.016 0-3.016 0-4 2-4 4 2 4 4 4h2.156c-0.75-0.5-1.453-1.391-1.672-2z" />
        </svg>
        #{title}
      </a>
    """
    click    : (event) ->
      if hash = event.target?.hash
        window.location.replace hash
