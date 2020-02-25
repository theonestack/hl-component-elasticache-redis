CfhighlanderTemplate do
  Name 'ElastiCacheRedis'
  Description "#{component_name} - #{component_version}"
  ComponentVersion component_version

  DependsOn 'vpc'

  Parameters do
    ComponentParam 'VPCId'
    ComponentParam 'StackOctet', isGlobal: true
    ComponentParam 'NetworkPrefix', isGlobal: true
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true, allowedValues: ['development', 'production']
    ComponentParam 'DnsDomain'
    ComponentParam 'SubnetIds', type: 'CommaDelimitedList'

    ComponentParam 'S3Snapshot', '' if restore_from_s3
    ComponentParam 'Snapshot', '' if restore_from_snapshot

    ComponentParam 'CacheInstanceType'
    ComponentParam 'CacheClusters', 1, allowedValues: [1,2,3,4,5,6]
    ComponentParam 'Cluster', 'false', allowedValues: ['true','false']
    ComponentParam 'NumNodeGroups', 1
    ComponentParam 'ReplicasPerNodeGroup', 0, allowedValues: [0,1,2,3,4,5]
    ComponentParam 'SnapshotRetentionLimit', 0
  end

end
