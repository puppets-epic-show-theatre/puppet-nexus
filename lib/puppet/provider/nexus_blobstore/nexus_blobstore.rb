# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/util/network_device/config'

# Implementation for the nexus_blobstore type using the Resource API.
class Puppet::Provider::NexusBlobstore::NexusBlobstore < Puppet::ResourceApi::SimpleProvider
  # Init connection to the rest api
  def initialize
    super
    local_device = Puppet::Util::NetworkDevice::Config.devices['localhost_nexus_rest_api']
    config_file = local_device['url'] unless local_device.nil?
    Puppet::ResourceApi::Transport.inject_device('nexus_rest_api', config_file) unless File.exist?(config_file)
  end

  # Return requested blobstores as resources
  def get(context, names = nil)
    res = context.transport.get_request(context, 'blobstores')

    context.err(res.body) unless res.success?

    Puppet::Util::Json.load(res.body).map { |blobstore|
      next unless names.include?(blobstore['name'])

      type = blobstore['type'].downcase # API returns 'File' instead of 'file'
      res = context.transport.get_request(context, "blobstores/#{type}/#{blobstore['name']}")

      next unless res.success? # skip unsupported blobstore types

      attributes = Puppet::Util::Json.load(res.body)
      {
        name: blobstore['name'],
        ensure: 'present',
        type: type,
        attributes: attributes
      }
    }.compact
  end

  # Create blobstores not yet existing in nexus repository manager
  def create(context, name, should)
    attributes = should[:attributes]
    attributes[:name] = name
    res = context.transport.post_request(context, "blobstores/#{should[:type]}", attributes)

    context.err(res.body) unless res.success?
  end

  # Update blobstore settings on existing blobstore
  def update(context, name, should)
    res = context.transport.put_request(context, "blobstores/#{should[:type]}/#{name}", should[:attributes])

    context.err(res.body) unless res.success?
  end

  # Delete blobstore which is set to absent
  def delete(context, name)
    res = context.transport.delete_request(context, "blobstores/#{name}")

    context.err(res.body) unless res.success?
  end

  def canonicalize(context, resources)
    resources.each do |resource|
      resource[:attributes] = deep_sort(resource[:attributes]) unless resource[:attributes].nil?
    end
  end

  def insync?(context, name, property_name, is_hash, should_hash)
    context.debug("Checking whether #{property_name} is out of sync")

    case name
    when :attributes
      is_attrs = deep_sort(is_hash[:attributes])
      should_attrs = deep_sort(should_hash[:attributes])

      # Strip out known credentials first (if they're set), since Nexus doesn't return those
      stripped_keys = [
        [:bucketConfiguration, :bucketSecurity, :secretAccessKey]
      ]

      stripped_keys.each do |path|
        is_attrs = deep_delete(is_attrs, path)
        should_attrs = deep_delete(should_attrs, path)
      end

      is_attrs == should_attrs
    else
      is_hash[name] == should_hash[name]
    end
  end

  def deep_delete(hash, *keys)
    *parents, last = keys
    parent = hash.dig(*parents)
    parent.delete(last) if parent.is_a?(Hash)
  end

  def deep_sort(obj)
    case obj
    when Hash
      obj.keys.sort.each_with_object({}) do |key, sorted|
        sorted[key] = deep_sort(obj[key])
      end
    when Array
      obj.map { |e| deep_sort(e) }
    else
      obj
    end
  end
end
