class Kite extends bongo.Model

  @share()

  @setSharedMethods
    instance: ['on','off','emit','once','many']

  constructor:(@api)->

    @on 'kite ready', ->
      api.fooMethod()
      api.barMethod console.log
      console.log 'kite is ready!!!'

    @on 'out of space', ->
      console.log 'no more space!'