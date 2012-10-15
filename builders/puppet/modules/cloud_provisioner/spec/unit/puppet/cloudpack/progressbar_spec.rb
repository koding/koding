require 'puppet'
require 'puppet/cloudpack'
require 'mocha'
require 'spec_helper'

describe Puppet::CloudPack.constants do

  it { should include("ProgressBar") }

end
