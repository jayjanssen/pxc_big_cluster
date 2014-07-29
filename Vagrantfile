# -*- mode: ruby -*-
# vi: set ft=ruby :

# Assumes a box from https://github.com/jayjanssen/packer-percona

# This sets up 3 nodes with a common PXC, but you need to run bootstrap.sh to connect them.

# This is designed for aws
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'aws'

require File.dirname(__FILE__) + '/lib/vagrant-common.rb'

$mysql_version = "56"
$region = 'us-west-1'
$pxc_instance_size = 'm3.large'  
$tester_instance_size = 'c3.large'
$security_groups = ['default','pxc']

nodes = 10
$node_array = (1..nodes).collect{ |i| 'node' + i.to_s }
$cluster_address = "gcomm://" + $node_array.join(',')
	
hostmanager_aws_ips='private'


Vagrant.configure("2") do |config|
	config.vm.box = "perconajayj/centos-x86_64"
	config.ssh.username = "root"
	
	# it's disabled by default, it's done during the provision phase
	config.hostmanager.enabled = false
	config.hostmanager.include_offline = true

	$node_array.each do |node_name|
		config.vm.define node_name do |node_config|
			node_config.vm.hostname = node_name
		  
		  # Provisioners
			config.vm.provision :hostmanager
			
		  provision_puppet( node_config, "base.pp" )
		  provision_puppet( node_config, "pxc_server.pp" ) { |puppet|
				puppet.facter = {
					"percona_server_version"	=> $mysql_version,
					'innodb_buffer_pool_size' => '5G',
					'innodb_log_file_size' => '64M',
					'innodb_flush_log_at_trx_commit' => '0',
					'pxc_bootstrap_node'				=> (node_name == 'node1' ? true : false),
					'extra_mysqld_config'				=>
						'wsrep_provider_options="gcs.fc_limit=2048;ist.recv_addr="' + node_name + "\"\n" +
						'wsrep_sst_receive_address=' + node_name + "\n" +
						'wsrep_node_address=' + node_name + "\n" +
						'wsrep_cluster_address=' + $cluster_address +
						"\n"
				}
		  }
		  provision_puppet( node_config, "percona_toolkit.pp" )
		  provision_puppet( node_config, "myq_gadgets.pp" )

			# Setup a sysbench environment and test user on node1
			if node_name == 'node1'
			  provision_puppet( node_config, "sysbench.pp" )
			  provision_puppet( node_config, "sysbench_load.pp" ) { |puppet|
					puppet.facter = {
						'tables' => 1,
						'rows' => 1000000,
						'threads' => 1
					}
				}
				provision_puppet( node_config, "test_user.pp" )
			end
	  
		  # Provider -- aws only
			provider_aws( "PXC big_cluster #{node_name}", node_config, $pxc_instance_size, $region, $security_groups, hostmanager_aws_ips ) { |aws, override|
				aws.block_device_mapping = [
					{
						'DeviceName' => "/dev/sdb",
						'VirtualName' => "ephemeral0"
					}
				]
				provision_puppet( override, "pxc_server.pp" ) {|puppet|
				  puppet.facter = {"datadir_dev" => "xvdb"}
				}
			}
		end
	end

end

