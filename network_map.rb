require 'colorize'
# require 'byebug'
require 'json'
# This class represents a network map with nodes and edges

class AWSNetworkMap
  attr_accessor :get_commands

  def initialize
    @get_commands = {
      vpc: 'aws ec2 describe-vpcs --vpc-ids {vpc_id} --output json',
      subnets: 'aws ec2 describe-subnets --filters Name=vpc-id,Values={vpc_id} --output json',
      security_groups: 'aws ec2 describe-security-groups --filters Name=vpc-id,Values={vpc_id} --output json',
      security_group_rules: 'aws ec2 describe-security-group-rules --filters Name="group-id",Values="{security_group}" --output json',
      instances: 'aws ec2 describe-instances --filters Name=vpc-id,Values={vpc_id} --output json',
      internet_gateway: 'aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values={vpc_id} --output json',
      network_interfaces: 'aws ec2 describe-network-interfaces --filters Name=vpc-id,Values={vpc_id} --output json',
      route_tables: 'aws ec2 describe-route-tables --filters Name=vpc-id,Values={vpc_id} --output json',
      network_acl: 'aws ec2 describe-network-acls --filters Name=vpc-id,Values={vpc_id} --output json',
      nat_gateways: 'aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values={vpc_id}" --output json',
      vpc_peering_requester: 'aws ec2 describe-vpc-peering-connections --filters Name=requester-vpc-info.vpc-id,Values={vpc_id} --output json',
      vpc_peering_accepter: 'aws ec2 describe-vpc-peering-connections --filters Name=accepter-vpc-info.vpc-id,Values={vpc_id} --output json',
      vpc_endpoints: 'aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values={vpc_id} --output json',
      rds_clusters: 'aws rds describe-db-clusters --output json',
    }
  end

  def _execute_command(command)
    output = `#{command}`
    if $?.success?
      return JSON.parse(output)
    else
      puts "Error executing command: #{output}".red
      nil
    end
  end

  def get_vpc(vpc_id)
    puts "Fetching VPC details for VPC ID: #{vpc_id}".green
    command = @get_commands[:vpc].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['Vpcs'].first : nil
  end

  def get_subnets(vpc_id)
    puts "Fetching Subnets for VPC ID: #{vpc_id}".green
    command = @get_commands[:subnets].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['Subnets'] : []
  end

  def get_security_groups(vpc_id)
    puts "Fetching Security Groups for VPC ID: #{vpc_id}".green
    command = @get_commands[:security_groups].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['SecurityGroups'] : []
    output2 = []

    for sg in output['SecurityGroups']
      puts "  Processing Security Group Rules: #{sg['GroupId']}".yellow
      # Fetching security group rules for each security group
      sg_rules_command = @get_commands[:security_group_rules].gsub('{security_group}', sg['GroupId'])
      sg_rules_output = self._execute_command(sg_rules_command)
      sg['Rules'] = sg_rules_output ? sg_rules_output['SecurityGroupRules'] : []
      output2 << sg
    end

    output2
  end

  def get_instances(vpc_id)
    puts "Fetching instances for VPC ID: #{vpc_id}".green
    command = @get_commands[:instances].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['Reservations'].flat_map { |r| r['Instances'] } : []
  end

  def get_internet_gateway(vpc_id)
    puts "Fetching Internet Gateway for VPC ID: #{vpc_id}".green
    command = @get_commands[:internet_gateway].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['InternetGateways'] : nil
  end

  def get_route_tables(vpc_id)
    puts "Fetching Route Tables for VPC ID: #{vpc_id}".green
    command = @get_commands[:route_tables].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['RouteTables'] : []
  end

  def get_network_acl(vpc_id)
    puts "Fetching Network ACLs for VPC ID: #{vpc_id}".green
    command = @get_commands[:network_acl].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['NetworkAcls'] : []
  end

  def get_network_interfaces(vpc_id)
    puts "Fetching Network Interfaces for VPC ID: #{vpc_id}".green
    command = @get_commands[:network_interfaces].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['NetworkInterfaces'] : []
  end

  def get_nat_gateways(vpc_id)
    puts "Fetching NAT Gateways for VPC ID: #{vpc_id}".green
    command = @get_commands[:nat_gateways].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['NatGateways'] : []
  end

  def get_vpc_peering_requester(vpc_id)
    puts "Fetching VPC Peering Requester for VPC ID: #{vpc_id}".green
    command = @get_commands[:vpc_peering_requester].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['VpcPeeringConnections'] : []
  end

  def get_vpc_peering_accepter(vpc_id)
    puts "Fetching VPC Peering Accepter for VPC ID: #{vpc_id}".green
    command = @get_commands[:vpc_peering_accepter].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['VpcPeeringConnections'] : []
  end

  def get_vpc_endpoints(vpc_id)
    puts "Fetching VPC Endpoints for VPC ID: #{vpc_id}".green
    command = @get_commands[:vpc_endpoints].gsub('{vpc_id}', vpc_id)
    output = self._execute_command(command)
    output ? output['VpcEndpoints'] : []
  end

  def get_rds_clusters(security_groups_ids)
    puts "Fetching RDS Clusters".green
    command = @get_commands[:rds_clusters]
    output = self._execute_command(command)
    clusters = output ? output['DBClusters'] : []

    clusters.filter do |cluster|
      security_groups = cluster['VpcSecurityGroups'].map { |sg| sg['VpcSecurityGroupId'] }

      # Check if any of the security group IDs match the provided security groups
      security_groups_ids.any? { |sg_id| security_groups.include?(sg_id) }
    end
  end

  def generate_report(vpc_id, file_path = nil)
    report = {}
    report[:vpc] = self.get_vpc(vpc_id)
    report[:subnets] = self.get_subnets(vpc_id)
    report[:security_groups] = self.get_security_groups(vpc_id)
    # report[:instances] = get_instances(vpc_id)
    report[:internet_gateways] = self.get_internet_gateway(vpc_id)
    report[:network_interfaces] = self.get_network_interfaces(vpc_id)
    report[:route_tables] = self.get_route_tables(vpc_id)
    report[:network_acls] = self.get_network_acl(vpc_id)
    report[:nat_gateways] = self.get_nat_gateways(vpc_id)
    report[:vpc_peering_requesters] = self.get_vpc_peering_requester(vpc_id)
    report[:vpc_peering_accepters] = self.get_vpc_peering_accepter(vpc_id)
    report[:vpc_endpoints] = self.get_vpc_endpoints(vpc_id)
    report[:rds_clusters] = self.get_rds_clusters(report[:security_groups].map { |sg| sg['GroupId'] })

    if file_path
      self.persist_on_file(file_path, report)
    end
    report
  end

  def persist_on_file(file_path, report)
    File.open(file_path, 'w') do |file|
      file.write(JSON.pretty_generate(report))
    end
    puts "Report persisted to #{file_path}".magenta
  end
end

# Example usage:
# require './network_map'
# network_map = AWSNetworkMap.new
# vpc_id = 'vpc-12345678'
# vpc_id = 'vpc-ce22fbb7'
# path = "#{vpc_id}_network_report.json"
# report = network_map.get_report(vpc_id, path)
# puts network_map.to_s
# puts JSON.pretty_generate(report)