begin
  require 'puppet/rails'
  require 'puppet/rails/resource'
  require 'puppet/util/log'

  module Puppet::Parser::Functions
    newfunction(:servers_with_role,
    :type => :rvalue,
    :doc => "Return all server objects with a certain role:
  
    servers_with_role('frontend', 'production)
    " ) do |args|
      
      log "fetching servers with role #{args}"
      
      environment ||= lookupvar("::environment")

      raise Puppet::ParseError, ("servers_with_role(): wrong number of arguments (#{args.length}; must be >= 1)") if args.length < 1

      begin
        return Puppet::Rails::Resource.where(:title => args, :restype => 'Server').all
      rescue
        log "an error occurred while querying for nodes"
        []
      end
    end
  end
  
  def log(msg)
    Puppet::Util::Log.create(
      :level   => :info,
      :message => msg,
      :source  => 'servers_with_role'
    )  
  end
  
rescue NameError
  # the puppet clients don't have any activerecord. see http://projects.puppetlabs.com/issues/12594
end