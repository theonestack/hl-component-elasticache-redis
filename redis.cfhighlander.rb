CfhighlanderTemplate do
  Name 'redis'
  Description "redis - #{component_version}"

  DependsOn 'lib-ec2@0.1.0'

  Parameters do
    
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true

    ComponentParam 'EnvironmentType', 'development', 
        allowedValues: ['development','production'], isGlobal: true

    ComponentParam 'DnsDomain'

    ComponentParam 'SnapshotName', nil
    ComponentParam 'SnapshotArns', nil, type: 'CommaDelimitedList'

    ComponentParam 'SnapshotRetentionLimit'

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'

    ComponentParam 'InstanceType', 't3.small'

    ComponentParam 'Subnets', type: 'CommaDelimitedList'

    if replication_mode.eql?('node_group')
      ComponentParam 'NumNodeGroups', 1
      ComponentParam 'ReplicasPerNodeGroup', 0,
      allowedValues: [0, 1, 2, 3, 4, 5]
    elsif replication_mode.eql?('cache_cluster')
      ComponentParam 'NumCacheClusters', 2,
        allowedValues: [2, 3, 4, 5, 6]
    end

  end

end