CfhighlanderTemplate do
  Name 'redis'
  Description "redis - #{component_version}"

  DependsOn 'lib-ec2@0.1.0'

  Parameters do
    
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true

    ComponentParam 'EnvironmentType', 'development', 
      allowedValues: ['development','production'], isGlobal: true

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'

    ComponentParam 'DnsDomain'

    if snapshot_restore_type.eql?('native')
      ComponentParam 'SnapshotName',
        description: 'The name of a snapshot from which to restore data into the new replication group'
    elsif snapshot_restore_type.eql?('s3')
      ComponentParam 'SnapshotArns', type: 'CommaDelimitedList',
        description: 'A list of ARNs that uniquely identify the Redis RDB snapshot files stored in S3'
    end if defined? snapshot_restore_type

    ComponentParam 'SnapshotRetentionLimit',
      description: 'The number of days for which ElastiCache retains automatic snapshots before deleting them.'

    ComponentParam 'InstanceType', 'cache.t3.small',
      description: 'The compute and memory capacity of the nodes in the node group (shard)'

    ComponentParam 'Subnets', type: 'CommaDelimitedList',
      description: 'Comma-delimited list of subnets to launch redis in'

    if replication_mode.eql?('node_group')
      ComponentParam 'NumNodeGroups', '1',
        description: 'Specifies the number of node groups (shards) for this Redis replication group'
      ComponentParam 'ReplicasPerNodeGroup', '0',
        allowedValues: ['0', '1', '2', '3', '4', '5'],
        description: 'An optional parameter that specifies the number of replica nodes in each node group (shard). Valid values are 0 to 5.'
    elsif replication_mode.eql?('cache_cluster')
      ComponentParam 'NumCacheClusters', '2',
        allowedValues: ['1', '2', '3', '4', '5', '6'],
        description: 'The number of clusters this replication group initially has'
    end

    ComponentParam 'DataTieringEnabled', 'false', allowedValues: ['false', 'true'],
      description: 'Enables DataTiering and requires InstanceType to be a r6gd type'

  end

end