class ContentDisplay extends MainTabPane

  constructor:(options={}, data)->

    options.cssClass = KD.utils.curry "content-display-wrapper content-page", options.cssClass

    super