class CloudInstanceItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = "cloud-item #{data.provider}"
    super options, data

    @selectButton = new KDButtonView
      title    : "select"
      cssClass : "solid small green"
      callback : =>
        @getDelegate().emit "InstanceSelected", this

  viewAppended: JView::viewAppended

  pistachio:-> """
    {h2{ #(title) }}
    cpu: {{ #(spec.cpu)}}x - ram: {{ #(spec.ram)}} mb - storage: {{ #(spec.storage)}} GB
    {{ #(price) }} {{> @selectButton}}
  """
