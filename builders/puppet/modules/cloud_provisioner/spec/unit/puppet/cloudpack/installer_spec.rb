require 'tempfile'
require 'fileutils'
require 'puppet'
require 'puppet/cloudpack'
require 'puppet/cloudpack/installer'
require 'mocha'
require 'spec_helper'
installer_klass = Puppet::CloudPack::Installer
script_dir_name='scripts'
scripts_dir=File.expand_path("#{File.dirname(__FILE__)}/../../../../lib/puppet/cloudpack/#{script_dir_name}")
describe installer_klass do
  def tmp_template(content = 'Here is a <%= options[:variable] %>',name='foo', script_dir_name='scripts')
    tmp_file = Tempfile.new(name).path
    tmp_filename = File.basename(tmp_file)
    tmp_basedir = File.join(File.dirname(tmp_file), script_dir_name)
    FileUtils.mkdir(tmp_basedir) unless File.exists?(tmp_basedir)
    tmp_file_real = File.join(tmp_basedir, "#{tmp_filename}.erb")
    FileUtils.mv(tmp_file, tmp_file_real)
    File.open(tmp_file_real, 'w') do |fh|
      fh.write content
    end
    Puppet[:confdir] = File.dirname(tmp_file)
    tmp_file_real
  end
  describe 'when searching for file location' do
    it 'should override the system script with a users script' do
      template_location = tmp_template
      template_id = File.basename(template_location).gsub(/\.erb$/, '')
      installer_klass.find_template(template_id).should == template_location
    end
    it 'should be able to use a lib version' do
      File.expand_path(installer_klass.find_template('puppet-enterprise')).should == File.join(scripts_dir, 'puppet-enterprise.erb')
    end
    it 'should fail when it cannot find a script' do
      now = Time.now.to_i
      expect { installer_klass.find_template("foo_#{now}") }.should raise_error(Exception, /Could not find/)
    end
  end
  describe 'when compiling the script' do
    it 'should be able to compile erb templates' do
      template_location = tmp_template
      template_id = File.basename(template_location).gsub(/\.erb$/, '')
      Puppet::CloudPack::Installer.build_installer_template(template_id, {:variable => 'bar'}).should == 'Here is a bar'
    end
  end
end
