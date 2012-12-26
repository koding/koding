#
# Cookbook Name:: nginx
# Attributes:: geoip
#
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#
# Copyright 2012, Riot Games
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

default['nginx']['geoip']['path']                 = "/srv/geoip"
default['nginx']['geoip']['enable_city']          = true
default['nginx']['geoip']['country_dat_url']      = "http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz"
default['nginx']['geoip']['country_dat_checksum'] = "bbd5ea2bf1de800237a56ea0600f3d8ede2e2956937a8e632118f397af75adfa"
default['nginx']['geoip']['city_dat_url']         = "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
default['nginx']['geoip']['city_dat_checksum']    = "097f74d8295f82ca256d522497c3a105aaa6a353260c5d2c084156b29a54d431"
default['nginx']['geoip']['lib_version']          = "1.4.8"
default['nginx']['geoip']['lib_url']              = "http://geolite.maxmind.com/download/geoip/api/c/GeoIP-#{node['nginx']['geoip']['lib_version']}.tar.gz"
default['nginx']['geoip']['lib_checksum']         = "cf0f6b2bac1153e34d6ef55ee3851479b347d2b5c191fda8ff6a51fab5291ff4"
