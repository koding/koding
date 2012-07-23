class WidgetButton extends KDButtonViewWithMenu

  setTitle:(title)->

    @$('button').append("<span class='title'>#{title}</span>")

  click:(event)->

    @contextMenu event
    return no

  decorateButton:(tabName, title)->

    @$('button span.icon').attr "class","icon #{tabName}"
    @$('button span.title').text title
