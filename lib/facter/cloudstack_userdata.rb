# cloudstack_userdata.rb:
#
# This script will load the userdata associated with a CloudStack
# guest VM into a collection of puppet facts. It is assumed that
# the userdata is formated as key=value pairs, one pair per line.
# For example, if you set your userdata to "role=foo\nenv=development\n"
# two facts would be created, "role" and "env", with values
# "foo" and "development", respectively.
#
# A guest VM can get access to its userdata by making an http
# call to its virtual router. We can determine the IP address
# of the virtual router by inspecting the dhcp lease file on
# the guest VM.
#
# Copyright (C) 2011 Jason Hancock http://geek.jasonhancock.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.

require 'facter'

ENV['PATH']='/bin:/sbin:/usr/bin:/usr/sbin'

# The dirs to search for the dhcp lease files in. Works for RHEL/CentOS and Ubuntu
dirs = ['/var/lib/dhclient', '/var/lib/dhcp3', '/var/lib/dhcp']

regex = Regexp.new(/dhclient.+lease/)

dirs.each do |lease_dir|
    if !File.directory? lease_dir
        next
    end

    Dir.entries(lease_dir).each do |file|
        result = regex.match(file)
    
        # Expand file back into the absolute path
        file = lease_dir + '/' + file

        if result && File.size?(file) != nil
            cmd = sprintf("grep dhcp-server-identifier %s | tail -1 | awk '{print $NF}' | /usr/bin/tr '\;' ' '", file)
        
            virtual_router = `#{cmd}`
            virtual_router.strip!

            cmd = sprintf('wget -q -O - http://%s/latest/user-data', virtual_router)
            result = `#{cmd}`

            lines = result.split("\n")

            lines.each do |line|
                if line =~ /^(.+)=(.+)$/
                    var = $1; val = $2
                    var = var.gsub("#", "")
                    Facter.add(var) do
                        setcode { val }
                    end
                end
            end

            # use the older method of http://virtual_router_ip/latest/{metadata-type}
            # because the newer http://virtual_router_ip/latest/meta-data/{metadata-type}
            # was 404'ing on CloudStack v2.2.12
            cmd = sprintf('wget -q -O - http://%s/latest/instance-id', virtual_router)
            result = `#{cmd}`

            Facter.add('instance_id') do
                setcode { result }
            end
        end
    end
end
