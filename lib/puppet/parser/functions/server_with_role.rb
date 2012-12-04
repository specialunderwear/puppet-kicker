begin
  require 'puppet/util/log'

  module Puppet::Parser::Functions
    newfunction(:server_with_role,
    :type => :rvalue,
    :doc => "Return one server object with a certain role:
  
    server_with_role('frontend', { fallback => 'somevalue' })
    " ) do |args|
      Puppet::Parser::Functions.autoloader.loadall

      fallback = nil

      if args.kind_of?(Array) and args.count > 1
          fallback = args.pop
      end

      servers = function_servers_with_role(args)
      servers.count > 0 ? servers[0] : fallback
    end
  end

rescue NameError, LoadError
  # the puppet clients don't have any activerecord. see http://projects.puppetlabs.com/issues/12594
end
