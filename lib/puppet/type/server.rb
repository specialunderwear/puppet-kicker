# puppet type that can be used to describe a server.
# you can then collect all servers with a certain role using
# $font_and_back = servers_with_role('frontend', 'production)

Puppet::Type.newtype(:server) do
  @doc = "A type to describe a sever with a specific role"
  newparam(:role) do
    desc "The role of the server"
    isnamevar
  end
  newparam(:hostname) do
    desc "the short hostname at which the server is available"
  end
  newparam(:ipaddress) do
    desc "The ip address at which the server is available"
  end
  newparam(:fqdn) do 
    desc "The fully qualified domain name of the server"
  end
  newparam(:ports) do
    desc "The ports the server is running on"
  end
end