CloudFormation do
  
  redis_tags = []
  redis_tags << { Key: 'Name', Value: FnSub("${EnvironmentName}-#{external_parameters[:component_name]}") }
  redis_tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
  redis_tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }

  ip_blocks = external_parameters.fetch(:ip_blocks, {})
  security_group_rules = external_parameters.fetch(:security_group_rules, [])

  EC2_SecurityGroup(:SecurityGroupRedis) {
    VpcId Ref(:VPCId)
    GroupDescription FnSub("${EnvironmentName}-#{external_parameters[:component_name]}")
    
    if security_group_rules.any?
      SecurityGroupIngress generate_security_group_rules(security_group_rules,ip_blocks)
    end

    SecurityGroupEgress([
      {
        CidrIp: '0.0.0.0/0',
        Description: "Outbound for all ports",
        IpProtocol: -1,
      }
    ])

    Tags redis_tags
  }

  Output(:RedisSecurityGroupId) {
    Value Ref(:SecurityGroupRedis)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-RedisSecurityGroup")
  }

  ElastiCache_SubnetGroup(:SubnetGroupRedis) {
    Description FnSub("${EnvironmentName}-#{external_parameters[:component_name]}")
    SubnetIds Ref(:Subnets)
  }

  custom_parameters = external_parameters.fetch(:parameters, [])
  family = external_parameters.fetch(:family, 'redis4.0')
  cluster_enabled = external_parameters.fetch(:cluster_enabled, 'true')

  if cluster_enabled
    record_endpoint = 'ConfigurationEndPoint.Address'
    final_parameters = { 'cluster-enabled': 'yes' }
  else 
    record_endpoint = 'PrimaryEndPoint.Address'
    final_parameters = { 'cluster-enabled': 'no' }
  end

  final_parameters.merge!(custom_parameters) unless custom_parameters.empty?

  ElastiCache_ParameterGroup(:ParameterGroupRedis) {
    CacheParameterGroupFamily family
    Description FnSub("${EnvironmentName}-#{external_parameters[:component_name]}")
    Properties final_parameters
  }

  engine_version = external_parameters.fetch(:engine_version, nil)
  redis_port = external_parameters.fetch(:redis_port, nil)

  transit_encryption = external_parameters.fetch(:transit_encryption, true)
  at_rest_encryption = external_parameters.fetch(:at_rest_encryption, true)
  kms_key_id = external_parameters.fetch(:kms_key_id, nil)

  minor_upgrade = external_parameters.fetch(:minor_upgrade, true)
  snapshot_window = external_parameters.fetch(:snapshot_window, nil)
  maintenance_window = external_parameters.fetch(:maintenance_window, nil)

  replication_mode = external_parameters.fetch(:replication_mode, 'node_group')
  automatic_failover = external_parameters.fetch(:automatic_failover, true)

  ElastiCache_ReplicationGroup(:ReplicationGroupRedis) {

    ReplicationGroupDescription FnSub("${EnvironmentName}-#{external_parameters[:component_name]}")

    Engine 'redis'
    EngineVersion engine_version unless engine_version.nil?
    Port redis_port unless redis_port.nil?

    TransitEncryptionEnabled transit_encryption
    AtRestEncryptionEnabled at_rest_encryption
    KmsKeyId kms_key_id if (at_rest_encryption == true) && (!kms_key_id.nil?)
    AutoMinorVersionUpgrade minor_upgrade
    AutomaticFailoverEnabled automatic_failover

    CacheNodeType Ref(:InstanceType)
    CacheParameterGroupName Ref(:ParameterGroupRedis)
    CacheSubnetGroupName Ref(:SubnetGroupRedis)

    SecurityGroupIds [ Ref(:SecurityGroupRedis) ]
    
    if replication_mode.eql?('node_group')
      NumNodeGroups Ref(:NumNodeGroups)
      ReplicasPerNodeGroup Ref(:ReplicasPerNodeGroup)
    elsif replication_mode.eql?('cache_cluster')
      NumCacheClusters Ref(:NumCacheClusters)
    end 

    snapshot_restore_type = external_parameters.fetch(:snapshot_restore_type, nil)

    if snapshot_restore_type.eql?('native')
      SnapshotName Ref(:SnapshotName)
    elsif snapshot_restore_type.eql?('s3')
      SnapshotArns Ref(:SnapshotArns)
    end unless snapshot_restore_type.nil?

    SnapshotRetentionLimit Ref(:SnapshotRetentionLimit)

    SnapshotWindow snapshot_window unless snapshot_window.nil?
    PreferredMaintenanceWindow maintenance_window unless maintenance_window.nil?

    Tags redis_tags

  }

  dns_domain = external_parameters.fetch(:dns_domain)
  record = external_parameters.fetch(:record, 'redis')

  Route53_RecordSet(:HostRecordRedis) {
    HostedZoneName FnSub("#{dns_domain}.")
    Name FnSub("#{record}.#{dns_domain}.")
    Type 'CNAME'
    TTL '60'
    ResourceRecords [ FnGetAtt(:ReplicationGroupRedis, record_endpoint) ]
  }

end