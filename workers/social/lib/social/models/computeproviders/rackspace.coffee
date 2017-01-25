ProviderInterface = require './providerinterface'

module.exports = class Rackspace extends ProviderInterface

  @ping = (client, options, callback) ->

    callback null, "Rackspace is cool #{ client.r.account.profile.nickname }!"

  @supportsStacks = no

  @create = (client, options, callback) ->

    { imageId, credential, instanceType, region } = options

    meta = {
      type     : 'rackspace'
      imageId  : imageId      ? 'bb02b1a3-bc77-4d17-ab5b-421d89850fca'
      flavorId : instanceType ? '2'
      region   : region       ? 'IAD'
    }

    callback null, { meta, credential }


  @fetchAvailable = (client, options, callback) ->

    callback null, [
      {
        name  : '2'
        title : '512MB Standard Instance'
        spec  : {
          cpu : 1, ram : 512, storage: 20
        }
        price : '$16.06 per Month'
      }
      {
        name  : '3'
        title : '1GB Standard Instance'
        spec  : {
          cpu : 1, ram : 1024, storage: 40
        }
        price : '$43.80 per Month'
      }
      {
        name  : '4'
        title : '2GB Standard Instance'
        spec  : {
          cpu : 2, ram : 2048, storage: 80
        }
        price : '$87.60 per Month'
      }
      {
        name  : '5'
        title : '4GB Standard Instance'
        spec  : {
          cpu : 2, ram : 4096, storage: 160
        }
        price : '$175.20 per Month'
      }
      {
        name  : '6'
        title : '8GB Standard Instance'
        spec  : {
          cpu : 4, ram : 8192, storage: 320
        }
        price : '$350.40 per Month'
      }
      {
        name  : '7'
        title : '15GB Standard Instance'
        spec  : {
          cpu : 6, ram : 15360, storage: 620
        }
        price : '$657.00 per Month'
      }
      {
        name  : '8'
        title : '30GB Standard Instance'
        spec  : {
          cpu : 8, ram : 30720, storage: 1200
        }
        price : '$876.00 per Month'
      }
      {
        name  : 'performance1-1'
        title : '1 GB Performance'
        spec  : {
          cpu : 1, ram : 1024, storage: 20
        }
        price : '$29.20 per Month'
      }
      {
        name  : 'performance1-2'
        title : '2 GB Performance'
        spec  : {
          cpu : 2, ram : 2048, storage: 40
        }
        price : '$58.40 per Month'
      }
      {
        name  : 'performance1-4'
        title : '4 GB Performance'
        spec  : {
          cpu : 4, ram : 4096, storage: 40
        }
        price : '$116.80 per Month'
      }
      {
        name  : 'performance1-8'
        title : '8 GB Performance'
        spec  : {
          cpu : 8, ram : 8192, storage: 40
        }
        price : '$233.60 per Month'
      }
      {
        name  : 'performance2-120'
        title : '120 GB Performance'
        spec  : {
          cpu : 32, ram : 122880, storage: 40
        }
        price : '$496.40 per Month'
      }
      {
        name  : 'performance2-15'
        title : '15 GB Performance'
        spec  : {
          cpu : 4, ram : 15360, storage: 40
        }
        price : '$992.80 per Month'
      }
      {
        name  : 'performance2-30'
        title : '30 GB Performance'
        spec  : {
          cpu : 8, ram : 30720, storage: 40
        }
        price : '$ per Month'
      }
      {
        name  : 'performance2-60'
        title : '60 GB Performance'
        spec  : {
          cpu : 16, ram : 61440, storage: 40
        }
        price : '$1,985.60 per Month'
      }
      {
        name  : 'performance2-90'
        title : '90 GB Performance'
        spec  : {
          cpu : 24, ram : 92160, storage: 40
        }
        price : '$2,978.40 per Month'
      }
    ]
