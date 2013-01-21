require 'erb'
require 'puppet'
require 'puppet/cloudpack'
module Puppet::CloudPack::Installer

  class << self

    def build_installer_template(name, options = {})
      # binding is a kernel method
      ERB.new(File.read(find_template(name))).result(binding)
    end

    def lib_script_dir
      File.join(File.dirname(__FILE__), 'scripts')
    end

    def find_template(name)
      user_script = File.join(Puppet[:confdir], 'scripts', "#{name}.erb")
      return user_script if File.exists?(user_script)
      lib_script = File.join(lib_script_dir, "#{name}.erb")
      if File.exists?(lib_script)
        lib_script
      else
        raise "Could not find installation template for #{name}"
      end
    end
  end

end
