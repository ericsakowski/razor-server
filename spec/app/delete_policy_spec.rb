require_relative '../spec_helper'
require_relative '../../app'

describe "delete-policy" do
  include Rack::Test::Methods

  let(:app) { Razor::App }
  before :each do
    authorize 'fred', 'dead'
  end

  def delete_policy(name=nil)
    params = Hash.new
    params["name"] = name unless name.nil?
    post '/api/commands/delete-policy', params.to_json
  end

  before :each do
    header 'content-type', 'application/json'
  end

  it "should complain about no policy name" do
    count = Policy.count
    delete_policy()
    last_response.status.should == 400
    last_response.json["error"].should =~ /Supply 'name'/
    Policy.count.should == count
  end

  it "should advise about policy not existing" do
    count = Policy.count
    delete_policy('non-exist')
    last_response.status.should == 202
    last_response.json["result"].should =~ /no changes/
    Policy.count.should == count
  end

  it "should delete an existing policy" do
    policy = Fabricate(:policy)
    count = Policy.count
    delete_policy(policy.name)
    last_response.status.should == 202
    last_response.json["result"].should =~ /policy destroyed/
    Policy[:id => policy.id].should be_nil
    Policy.count.should == count-1
  end

  it "should delete the policy and disassociate from node, node remains installed" do
    node = Fabricate(:bound_node, :installed => 'some_os',
                     :installed_at => DateTime.now)
    delete_policy(node.policy.name)
    last_response.status.should == 202
    last_response.json["result"].should =~ /policy destroyed/
    Node[:id => node.id].policy_id.should be_nil
    Node[:id => node.id].installed.should == 'some_os'
    Node[:id => node.id].installed_at.should_not be_nil
  end
end
