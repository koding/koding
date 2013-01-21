#
# Cookbook Name:: dmg
# Provider:: package
#
# Copyright 2011, Joshua Timberman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def load_current_resource
  @dmgpkg = Chef::Resource::DmgPackage.new(new_resource.name)
  @dmgpkg.app(new_resource.app)
  Chef::Log.debug("Checking for application #{new_resource.app}")
  @dmgpkg.installed(installed?)
end

action :install do
  unless @dmgpkg.installed

    volumes_dir = new_resource.volumes_dir ? new_resource.volumes_dir : new_resource.app
    dmg_name = new_resource.dmg_name ? new_resource.dmg_name : new_resource.app
    dmg_file = "#{Chef::Config[:file_cache_path]}/#{dmg_name}.dmg"

    remote_file "#{dmg_file} - #{@dmgpkg.name}" do
      path dmg_file
      source new_resource.source
      checksum new_resource.checksum if new_resource.checksum
      only_if { new_resource.source }
    end

    passphrase_cmd = new_resource.dmg_passphrase ? "-passphrase #{new_resource.dmg_passphrase}" : ""
    ruby_block "attach #{dmg_file}" do
      block do
        software_license_agreement = system("hdiutil imageinfo #{passphrase_cmd} '#{dmg_file}' | grep -q 'Software License Agreement: true'")
        raise "Requires EULA Acceptance; add 'accept_eula true' to package resource" if software_license_agreement && !new_resource.accept_eula
        accept_eula_cmd = new_resource.accept_eula ? "echo Y |" : ""
        system "#{accept_eula_cmd} hdiutil attach #{passphrase_cmd} '#{dmg_file}'"
      end
      not_if "hdiutil info #{passphrase_cmd} | grep -q 'image-path.*#{dmg_file}'"
    end

    case new_resource.type
    when "app"
      execute "cp -R '/Volumes/#{volumes_dir}/#{new_resource.app}.app' '#{new_resource.destination}'" do
        user new_resource.owner if new_resource.owner
      end

      file "#{new_resource.destination}/#{new_resource.app}.app/Contents/MacOS/#{new_resource.app}" do
        mode 0755
        ignore_failure true
      end
    when "mpkg", "pkg"
      execute "sudo installer -pkg '/Volumes/#{volumes_dir}/#{new_resource.app}.#{new_resource.type}' -target /"
    end

    execute "hdiutil detach '/Volumes/#{volumes_dir}'"
  end
end

private

def installed?
  if ( ::File.directory?("#{new_resource.destination}/#{new_resource.app}.app") )
    Chef::Log.info "Already installed; to upgrade, remove \"#{new_resource.destination}/#{new_resource.app}.app\""
    true
  elsif ( system("pkgutil --pkgs=#{new_resource.package_id}") )
    Chef::Log.info "Already installed; to upgrade, try \"sudo pkgutil --forget #{new_resource.package_id}\""
    true
  else
    false
  end
end