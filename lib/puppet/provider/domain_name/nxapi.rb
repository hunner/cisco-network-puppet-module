# The NXAPI provider for cisco domain_name.
#
# October, 2015
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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

require 'cisco_node_utils' if Puppet.features.cisco_node_utils?
begin
  require 'puppet_x/cisco/autogen'
rescue LoadError # seen on master, not on agent
  # See longstanding Puppet issues #4248, #7316, #14073, #14149, etc. Ugh.
  require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..',
                                     'puppet_x', 'cisco', 'autogen.rb'))
end

Puppet::Type.type(:domain_name).provide(:nxapi) do
  desc 'The Cisco NXAPI provider for domain_name'

  confine feature: :cisco_node_utils
  defaultfor operatingsystem: :nexus

  mk_resource_methods

  def initialize(value={})
    super(value)
    @domains = Cisco::DomainName.domainnames
    @property_flush = {}
  end

  def self.properties_get(name, vrf=nil)
    current_state = {
      name:   "#{name}",
      vrf:    vrf.nil? ? 'default' : vrf,
      ensure: :present,
    }

    new(current_state)
  end # self.properties_get

  def self.instances
    # VRF support should iterate through list of VRFs and return an array containing
    # the set domain name for each VRF
    domains = []
    Cisco::DomainName.domainnames.each do |name, vrf|
      domains << properties_get(name, vrf)
    end

    domains
  end

  def self.prefetch(resources)
    domains = instances
    resources.keys.each do |name|
      provider = domains.find { |domain| domain.name == name }
      resources[name].provider = provider unless provider.nil?
    end
  end # self.prefetch

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_hash[:ensure] = :present
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def validate
    # A general check to make sure the provided string resembles a valid domain name.
    # Reference: Regular Expressions Cookbook, 2nd Edition, Section 8.15
    fail ArgumentError, 'Invalid domain_name provided.' unless @resource[:name] =~ /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/
  end

  def flush
    validate
  end
end # Puppet::Type
