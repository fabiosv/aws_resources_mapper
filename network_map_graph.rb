require 'json'

class AWSNetworkMapGraph
    def initialize
        @nodes = []
        @edges = []
        @data = nil
    end

    def load_map(vpc_id)
        path = "#{vpc_id}_network_map.json"

        if File.exist?(path)
            file = File.read(path)
            @data = JSON.parse(file)
        else
            puts "File not found: #{path}"
        end
    end

    def build_map(vpc_id)
        if @data.nil?
            load_map(vpc_id)
        end
        @nodes.clear
        @edges.clear

        @nodes << vpc_id

        self._load_subnets
        self._load_security_groups
        self._load_network_interfaces
        self._load_network_acl
        self._load_internet_gateway
        self._load_route_tables
        # Additional loaders can be added here

        output = { nodes: @nodes.uniq, edges: @edges.uniq }

        self.persist_on_file("#{vpc_id}_network_graph.json", output)

        output
    end


    def add_node(node)
        @nodes << node unless @nodes.include?(node)

        @nodes.flatten!
    end

    def add_edge(edge)
        @edges << edge unless @edges.include?(edge)
    end

    def to_s
        output = "Network Map:\n"
        output += "Nodes:\n"
        @nodes.each { |node| output += " - #{node}\n" }
        output += "Edges:\n"
        @edges.each { |edge| output += " - #{edge.first} -> #{edge.last}\n" }
        output
    end

    # Load Subnets relationship
    def _load_subnets
        @data['subnets'].each do |subnet|
            self.add_node(subnet['SubnetId'])
            self.add_node(subnet['CidrBlock'])
            self.add_edge([subnet['SubnetId'], subnet['CidrBlock']])
        end
        # _edges = @data['subnets'].map { |subnet| [subnet['SubnetId'], subnet['VpcId']] }
        # _edges.each do |edge|
        #     source = edge.first
        #     target = edge.last
        #     if target
        #         self.add_edge([source, target])
        #     end
        # end
    end

    # Load security groups relationship
    # source: security group ID
    # target: security group ID referenced in the rules Inbound/Outbound
    def _load_security_groups
        @nodes << @data['security_groups'].map { |sg| sg['GroupId'] }
        @data['security_groups'].each do |sg|
            self.add_edge([sg['GroupId'], sg['VpcId']]) if sg['VpcId']

            sg['Rules'].each do |rule|
                if rule['ReferencedGroupInfo']
                    target_group_id = rule['ReferencedGroupInfo']['GroupId']
                    self.add_edge([sg['GroupId'], target_group_id])
                end
                # Add edge for the CIDR block if it exists
                if rule['CidrIpv4']
                    self.add_edge([sg['GroupId'], rule['CidrIpv4']])
                end
                # Add edge for the IPv6 CIDR block if it exists
                if rule['CidrIpv6']
                    self.add_edge([sg['GroupId'], rule['CidrIpv6']])
                end
            end
        end

        # _edges = @data['security_groups'].map { |sg| [sg['GroupId'], sg['Rules'].map { |rule| rule['ReferencedGroupInfo'] ? rule['ReferencedGroupInfo']['GroupId'] : nil } ] }
        # # @edges << _edges.map { |rule| [rule.first, rule.last.compact]}
        # _edges.each do |edge|
        #     source = edge.first
        #     edge.last.compact.each do |target|
        #         if target
        #             self.add_edge([source, target])
        #         end
        #     end
        # end
    end

    # Load Network Interface relationship
    # source: network interface ID
    # target: security group ID | subnet ID | VPC ID
    def _load_network_interfaces
        @nodes << @data['network_interfaces'].map { |ni| ni['NetworkInterfaceId'] }
        @data['network_interfaces'].each do |ni|
            ni['Groups'].each do |sg|
                self.add_edge([ni['NetworkInterfaceId'], sg['GroupId']])
            end
            self.add_edge([ni['NetworkInterfaceId'], ni['SubnetId']])
            self.add_edge([ni['NetworkInterfaceId'], ni['VpcId']])
        end
    end

    # Load Network ACL relationship
    # source: network ACL ID
    # target: subnet ID
    def _load_network_acl
        @data['network_acls'].each do |acl|
            self.add_node(acl['NetworkAclId'])
            self.add_edge([acl['NetworkAclId'], acl['VpcId']])
            acl['Associations'].each do |assoc|
                self.add_edge([acl['NetworkAclId'], assoc['SubnetId']])
            end
        end
    end

    # Load Internet Gateway relationship
    def _load_internet_gateway
        @data['internet_gateways'].each do |igw|
            self.add_node(igw['InternetGatewayId'])
            self.add_edge([igw['InternetGatewayId'], igw['Attachments'].first['VpcId']]) if igw['Attachments'] && !igw['Attachments'].empty?
        end
    end

    # Load Route Tables relationship
    # source: route table ID
    # target: subnet ID | internet gateway ID | network interface ID
    def _load_route_tables
        @data['route_tables'].each do |rt|
            self.add_node(rt['RouteTableId'])
            # self.add_edge([rt['RouteTableId'], rt['VpcId']])
            rt['Associations'].each do |assoc|
                self.add_edge([rt['RouteTableId'], assoc['SubnetId']]) if assoc['SubnetId']
            end
            rt['Routes'].each do |route|
                if route['GatewayId']
                    self.add_node(route['GatewayId'])
                    self.add_edge([rt['RouteTableId'], route['GatewayId']])
                elsif route['InstanceId']
                    self.add_node(route['InstanceId'])
                    self.add_edge([rt['RouteTableId'], route['InstanceId']])
                elsif route['NetworkInterfaceId']
                    self.add_node(route['NetworkInterfaceId'])
                    self.add_edge([rt['RouteTableId'], route['NetworkInterfaceId']])
                elsif route['VpcPeeringConnectionId']
                    self.add_node(route['VpcPeeringConnectionId'])
                    self.add_edge([rt['RouteTableId'], route['VpcPeeringConnectionId']])
                end
            end
        end
    end

    def persist_on_file(file_path, report)
        File.open(file_path, 'w') do |file|
            file.write(JSON.pretty_generate(report))
        end
        puts "Report persisted to #{file_path}"
    end

end