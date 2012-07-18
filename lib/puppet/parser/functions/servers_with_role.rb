begin
  require 'puppet/rails'
  require 'puppet/rails/resource'
  require 'puppet/util/log'

  module Puppet::Parser::Functions
    newfunction(:servers_with_role,
    :type => :rvalue,
    :doc => "Return all server objects with a certain role:
  
    servers_with_role('frontend', 'production)
    " ) do |roles|
      Puppet::Parser::Functions.autoloader.loadall
      
      log "fetching servers with role #{roles.join(' ')}"
      
      if roles.length == 1
          return function_servers_with_facts(["role=#{roles}"])
      else
          return function_servers_with_facts(["role=/^#{roles.join('$|^')}$/"])
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