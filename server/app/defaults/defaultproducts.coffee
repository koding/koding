class DefaultProducts
  
  @products = []
  @products.push new Product {
      name                : t 'Database'
      description         : t 'Databases are for storing data.'
      allocationOffsets   : [
        new Allocation unit: 'database'   , quota: 1
      ]
      payment     :
        recurring : [new Allocation unit: 'dollar', usage: 1]
        interval  : 'monthly'
        billBy    : 'quota'
        taxable   : no
    }
  @products.push new Product {
      name                : t 'Open-source repository'
      description         : t 'Support open source.'
      allocationOffsets   : [
        new Allocation unit: 'repository'   , quota: 1
      ]
      payment     :
        taxable   : no
    }
  @products.push new Product {
      name                : t 'Private repository'
      description         : t 'Use version control.'
      allocationOffsets   : [
        new Allocation unit: 'repository'   , quota: 1
      ]
      payment     :
        fees      : [new Allocation unit: 'dollar', usage: 5]
        recurring : [new Allocation unit: 'dollar', usage: 1]
        interval  : 'monthly'
        taxable   : no
    }
  @products.push new Product {
      name                : t 'Team member'
      description         : t 'Something pithy.'
      allocationOffsets   : [
        new Allocation unit: 'team member', quota: 1
      ]
      payment     :
        recurring : [new Allocation unit: 'dollar', usage: 1]
        interval  : 'monthly'
        taxable   : no
    }
  @products.push new Product {
      name                : t 'Domain'
      description         : t 'Something pithy.'
      allocationOffsets   : [
        new Allocation unit: 'domain', quota: 1
      ]
      payment     :
        recurring : [new Allocation unit: 'dollar', usage: 1]
        interval  : 'monthly'
        taxable   : no
    }
  @products.push new Product {
      name                : t 'Container'
      description         : t 'Something pithy.'
      allocationOffsets   : [
        new Allocation unit: 'container'   , quota: 1
      ]
      payment     :
        recurring : [new Allocation unit: 'dollar', usage: 50]
        type      : 'recurring'
        interval  : 'monthly'
        taxable   : no
    }
  @products.push new Product {
      name                : t 'Virtual machine'
      description         : t 'Something pithy.'
      allocationOffsets   : [new Allocation unit: 'vm', quota: 1]
      payment     :
        recurring : [new Allocation unit: 'dollar', usage: 1]
        type      : 'recurring'
        interval  : 'monthly'
        taxable   : no
    }