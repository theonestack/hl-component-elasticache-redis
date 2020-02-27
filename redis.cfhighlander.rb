CfhighlanderTemplate do
  Name 'redis'
  Description "redis - #{component_version}"

  DependsOn 'lib-ec2@0.1.0'

  Parameters do
    
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true

    ComponentParam 'EnvironmentType', 'development', 
        allowedValues: ['development','production'], isGlobal: true

    ComponentParam 'DnsDomain'

    ComponentParam 'SnapshotName'
    ComponentParam 'SnapshotArns', type: 'CommaDelimitedList'
    ComponentParam 'SnapshotRetentionLimit'

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'

    ComponentParam 'InstanceType', 't3.small'

    ComponentParam 'Subnets', type: 'CommaDelimitedList'

    ComponentParam 'NumNodeGroups', '1'

    ComponentParam 'NumCacheClusters', '2',
      allowedValues: ['2', '3', '4', '5', '6']

    ComponentParam 'ReplicasPerNodeGroup', '0',
      allowedValues: ['0', '1', '2', '3', '4', '5']

  end

end