require 'yaml'

describe 'should be valid' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/clustered.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/clustered/redis.compiled.yaml") }

  context 'Resource ReplicationGroupRedis' do

    let(:properties) { template["Resources"]["ReplicationGroupRedis"]["Properties"] }

    it 'has property' do
      expect(properties).to eq({
        "AtRestEncryptionEnabled" => true,
        "AutoMinorVersionUpgrade" => true,
        "AutomaticFailoverEnabled" => true,
        "CacheNodeType" => {"Ref"=>"InstanceType"},
        "CacheParameterGroupName" => {"Ref"=>"ParameterGroupRedis"},
        "CacheSubnetGroupName" => {"Ref"=>"SubnetGroupRedis"},
        "DataTieringEnabled" => {"Fn::If"=>["DataTieringEnabled", {"Ref"=>"DataTieringEnabled"}, {"Ref"=>"AWS::NoValue"}]},
        "Engine" => "redis",
        "NumNodeGroups" => {"Ref"=>"NumNodeGroups"},
        "Port" => 1234,
        "PreferredMaintenanceWindow" => "sun:03:25-sun:05:30",
        "ReplicasPerNodeGroup" => {"Ref"=>"ReplicasPerNodeGroup"},
        "ReplicationGroupDescription" => {"Fn::Sub"=>"${EnvironmentName}-redis"},
        "SecurityGroupIds" => [{"Ref"=>"SecurityGroupRedis"}],
        "SnapshotRetentionLimit" => {"Ref"=>"SnapshotRetentionLimit"},
        "SnapshotWindow" => "00:30-02:30",
        "Tags" => [
          {"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-redis"}},
          {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}},
          {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}
        ],
        "TransitEncryptionEnabled" => true,
      })
    end

  end

end