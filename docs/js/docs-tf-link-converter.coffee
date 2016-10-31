---
---

do ->

  $(document).ready ->

    $('section.markdown-body a').each (index, el) ->

      return  unless /^\/docs\//.test value = el.attributes.href?.value

      el.setAttribute 'href', value.replace '/docs/', '/docs/terraform/'
