require 'json'
require 'colorize'
require 'byebug'

namespace :network do
    desc 'Generate network map for a given VPC ID'
    task :map, [:vpc_id] do |t, args|
        require_relative 'network_map'
        vpc_id = args[:vpc_id] || ENV['VPC_ID']
        raise ArgumentError, "VPC ID is required" if vpc_id.nil? || vpc_id.empty?

        network_map = AWSNetworkMap.new
        path = "#{vpc_id}_network_report.json"
        report = network_map.generate_report(vpc_id, path)

        summary = {
            vpc_id: vpc_id.length,
            subnets: report[:subnets].length,
            security_groups: report[:security_groups].length,
            internet_gateways: report[:internet_gateways] ? 1 : 0,
            network_interfaces: report[:network_interfaces].length,
            route_tables: report[:route_tables].length,
            network_acls: report[:network_acls] ? 1 : 0,
            nat_gateways: report[:nat_gateways].length,
            vpc_peering_requesters: report[:vpc_peering_requesters].length,
            vpc_peering_accepters: report[:vpc_peering_accepters].length,
            vpc_endpoints: report[:vpc_endpoints].length
        }

        puts JSON.pretty_generate(summary)
    end

    desc 'Generate network graph report for a given VPC ID'
    task :report, [:vpc_id] do |t, args|
        require_relative 'network_map_graph'
        vpc_id = args[:vpc_id] || ENV['VPC_ID']

        raise ArgumentError, "VPC ID is required".red if vpc_id.nil? || vpc_id.empty?

        network_map = AWSNetworkMapGraph.new
        report = network_map.build_map(vpc_id)

        summary = {
            nodes: report[:nodes].length,
            edges: report[:edges].length
        }
        puts JSON.pretty_generate(summary)
    end
end