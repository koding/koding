---
---

do ->

  MAIN_UL = $ '#terraform-docs'
  docsMap = {}
  pageUrl = PAGE_URL

  # expandParents = (el) ->
  #   parent = el.closest('ul').show()
  #   expandParents parent  if parent.closest('ul').length
  getTitle = (raw) ->
    if /\:\s/.test raw
    then raw.split(': ').pop()
    else raw

  createUl = (doc, parent) ->

    ul = $ "<ul/>"
    if index = doc?.index
      isActive = pageUrl is index.url
      title = "<li class='title#{ if isActive then ' active' else ''}'><a href='{{ site.url }}#{index.url}'>#{getTitle index.title}</a></li>"
      parent.append title

    unless doc.title
      for own prop of doc
        createUl doc[prop], ul
      parent.find('li').last().append ul
    else
      unless /index\.html\/?/.test doc.url
        isActive = pageUrl is doc.url

        parent.append "<li #{ if isActive then 'class=\'active\'' else ''}><a href='{{ site.url }}#{doc.url}'>#{getTitle doc.title}</a></li>"


    return ul

  return  unless TERRAFORM_DOCS


  TERRAFORM_DOCS.forEach (doc) ->
    id = doc.url.replace('/docs/terraform/', '').split '/'
    id.pop()
    path = id.join '.'
    path = path.replace /\.html?/, ''
    lodash_set docsMap, path, doc

  docsMap.index.title = 'Stack Documentation'

  window.TERRAFORM_DOCS_MAP = docsMap

  createUl docsMap, MAIN_UL

  # expandParents active  if (active = $('li.active')).length
  $('aside li ul').hide()
  $('li.active > ul').show()
  $('li.active').parents('ul').show()

  $('li a[href="#"]').on 'click', (event) ->
    event.preventDefault()
    $(this).parent().find('> ul').show()

  $(document).ready ->
    $('section.markdown-body a').each (index, el) ->
      { value } = el.attributes.href

      if /^\/docs\//.test value
        el.setAttribute 'href', value.replace '/docs/', '/docs/terraform/'
