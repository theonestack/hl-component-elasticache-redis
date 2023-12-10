CloudFormation do

  Condition 'IsMaxOverFive', FnNot(FnOr([FnEquals(Ref(:Max),1), FnEquals(Ref(:Max),2), FnEquals(Ref(:Max),3), FnEquals(Ref(:Max),4), FnEquals(Ref(:Max),5)])) 

  cluster_enabled = external_parameters.fetch(:cluster_enabled, 'true')

  if cluster_enabled
    record_endpoint = 'ConfigurationEndPoint.Address'
    final_parameters = { 'cluster-enabled': 'yes' }
  else
    record_endpoint = 'PrimaryEndPoint.Address'
    final_parameters = { 'cluster-enabled': 'no' }
  end

  IAM_Role(:ServiceElastiCacheAutoScaleRole) do
    AssumeRolePolicyDocument service_assume_role_policy('application-autoscaling')
    Path '/'
    Policies ([
      PolicyName: 'elasticache-scaling',
      PolicyDocument: {
        Statement: [
          {
            Effect: "Allow",
            Action: ['cloudwatch:DescribeAlarms','cloudwatch:PutMetricAlarm','cloudwatch:DeleteAlarms'],
            Resource: "*"
          },
          {
            Effect: "Allow",
            Action: [
              "elasticache:Describe*",
              "elasticache:IncreaseReplicaCount",
              "elasticache:DecreaseReplicaCount",
              "elasticache:ModifyReplicationGroupShardConfiguration"
            ],
            Resource: [
               FnJoin('', [ FnSub("arn:aws:elasticache:${AWS::Region}:${AWS::AccountId}:cluster:"), FnSelect(0, FnSplit('.', FnGetAtt(:ReplicationGroupRedis, record_endpoint))), "*"]),
               FnJoin('', [ FnSub("arn:aws:elasticache:${AWS::Region}:${AWS::AccountId}:replicationgroup:"), FnSelect(0, FnSplit('.', FnGetAtt(:ReplicationGroupRedis, record_endpoint)))])
            ]
          }
        ]
    }])
  end

  # Supports only TargetTrackingScaling
  scaling_policy = external_parameters.fetch(:scaling_policy, {})
  scaling_policy.each_with_index do |scale_target_policy, i|

    ApplicationAutoScaling_ScalableTarget("ServiceScalingTarget" + (i > 0 ? "#{i+1}" : "")) do
      DependsOn [:ServiceElastiCacheAutoScaleRole]

      if (scale_target_policy['target'] == 'replicas')
        MaxCapacity FnIf('IsMaxOverFive', 5, Ref(:Max))
      else
        MaxCapacity Ref(:Max)
      end

      MinCapacity Ref(:Min)
      ResourceId FnJoin( '', [ "replication-group/", FnSelect(0, FnSplit('.', FnGetAtt(:ReplicationGroupRedis, record_endpoint))) ] )
      RoleARN FnGetAtt(:ServiceElastiCacheAutoScaleRole,:Arn)
      
      if (scale_target_policy['target'] == 'replicas') 
        ScalableDimension "elasticache:replication-group:Replicas"
      elsif (scale_target_policy['target'] == 'shards')
        ScalableDimension "elasticache:replication-group:NodeGroups"
      else
        ScalableDimension "elasticache:replication-group:Replicas"
      end

      ServiceNamespace "elasticache"
    end

    logical_scaling_policy_name = "ServiceTargetTrackingPolicy"  + (i > 0 ? "#{i+1}" : "")
    policy_name                 = "target-tracking-policy"       + (i > 0 ? "-#{i+1}" : "")

    ApplicationAutoScaling_ScalingPolicy(logical_scaling_policy_name) do
      DependsOn ["ServiceScalingTarget" + (i > 0 ? "#{i+1}" : "")]
      PolicyName FnJoin('-', [ Ref('EnvironmentName'), component_name, policy_name])
      PolicyType 'TargetTrackingScaling'
      ScalingTargetId Ref("ServiceScalingTarget" + (i > 0 ? "#{i+1}" : ""))
      TargetTrackingScalingPolicyConfiguration do
        TargetValue scale_target_policy['target_value']
        ScaleInCooldown scale_target_policy['scale_in_cooldown'].to_s
        ScaleOutCooldown scale_target_policy['scale_out_cooldown'].to_s
        PredefinedMetricSpecification do
          PredefinedMetricType scale_target_policy['metric_type'] || 'ElastiCacheReplicaEngineCPUUtilization'
        end unless scale_target_policy['metric_type'].nil?
        CustomizedMetricSpecification do
          Namespace scale_target_policy['custom']['namespace']
          MetricName scale_target_policy['custom']['metric_name']
          Statistic scale_target_policy['custom']['statistic']
          Unit scale_target_policy['custom']['unit'] unless scale_target_policy['custom']['unit'].nil?
          Dimensions scale_target_policy['custom']['dimensions'] unless scale_target_policy['custom']['dimensions'].nil?
        end unless scale_target_policy['custom'].nil?
      end
    end
  end unless scaling_policy.nil?

end
