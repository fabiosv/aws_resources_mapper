def persist_on_file(file_path, report)
  File.open(file_path, 'w') do |file|
    file.write(JSON.pretty_generate(report))
  end
  puts "Report persisted to #{file_path}".magenta
end

# ------------------------
# ----- AWS Network ------
# ------------------------

def map_network(vpc_id)
  require_relative 'network_map'

  network_map = AWSNetworkMap.new
  file_path = "#{vpc_id}_network_report.json"
  report = network_map.generate_report(vpc_id)

  persist_on_file(file_path, report)

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

def generate_network_graph(vpc_id)
  require_relative 'network_map_graph'

  network_map = AWSNetworkMapGraph.new
  report = network_map.build_map(vpc_id)

  persist_on_file("#{vpc_id}_network_graph.json", report)

  summary = {
      nodes: report[:nodes].length,
      edges: report[:edges].length
  }
  puts JSON.pretty_generate(summary)
end

# ------------------------
# ------- AWS IAM --------
# ------------------------

def map_iam
  require_relative 'iam_map'

  aws_iam = AWSIAMMap.new
  roles_report = aws_iam.build_roles_map
  policies_report = aws_iam.list_all_policies

  persist_on_file("iam_roles.json", roles_report)
  persist_on_file("iam_policies.json", policies_report)
end
