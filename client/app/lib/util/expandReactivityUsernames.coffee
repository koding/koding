$ = require 'jquery'

module.exports = (text, excludeSelector) ->
  # excludeSelector is a jQuery selector

  # as a jQuery selector, e.g. "pre"
  # means that all @s in <pre> tags will not be expanded

  return null  unless text

  replaceFunc = (text, isProfile) ->
    text.replace /\B\@([\w\-]+)/gim, (u) ->
      username = u.replace "@", ""
      return "<a href='#' class='profile-link'>#{u}</a>"  if isProfile
      return u.link "#"

  # default case for regular text
  if not excludeSelector
    replaceFunc text, yes

  # context-sensitive expansion
  else
    result = ""
    $(text).each (i, element) ->
      $element = $(element)
      elementCheck = $element.not excludeSelector
      parentCheck = $element.parents(excludeSelector).length is 0
      if elementCheck and parentCheck and $element.html()?
        ###
        we need to skip child nodes that meet to excludeSelector
        but we should not forget that @s may be found in a simple text
        ###
        $element.contents().each (j, child) ->
          $child = $(child)
          return  if $child.is excludeSelector

          isTextNode   = child.nodeType is Node.TEXT_NODE
          childContent = if isTextNode then $child.text() else $child.html()
          return  unless childContent

          replacedText = replaceFunc childContent, no

          if replacedText isnt childContent
            if isTextNode
              $child.wrap '<span>'
              $child.parent().html replacedText
            else
              $child.html replacedText

      result += $element.get(0).outerHTML or "" # in case there is a text-only element
    result

