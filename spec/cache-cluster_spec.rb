require 'yaml'

describe 'should be valid' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/cache-cluster.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/cache-cluster/redis.compiled.yaml") }

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
        "NumCacheClusters" => {"Ref"=>"NumCacheClusters"},
        "ReplicationGroupDescription" => {"Fn::Sub"=>"${EnvironmentName}-redis"},
        "SecurityGroupIds" => [{"Ref"=>"SecurityGroupRedis"}],
        "SnapshotRetentionLimit" => {"Ref"=>"SnapshotRetentionLimit"},
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