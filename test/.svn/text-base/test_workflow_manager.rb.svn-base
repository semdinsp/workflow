require File.dirname(__FILE__) + '/test_helper.rb'

class TestWorkflowManager < Test::Unit::TestCase

  def setup
  end
  
  def test_engine_creations
    wfe_engine= WorkflowManager::Engine.new('engine_creation')
    assert true
    
  end
  def test_engine_launch
    wfe_engine= WorkflowManager::Engine.new('test2')
     res=wfe_engine.launch("process")
      assert res=='failure', "res is #{res} but should be failure"
    
  end
  def test_engine_launch_process2
    wfe_engine= WorkflowManager::Engine.new('test3')
    res=wfe_engine.launch("process2")
    assert res=='all ok', "res is #{res}"
    
  end
  def test_engine_launch_process3
    begin
     wfe_engine= WorkflowManager::Engine.new('test4')
     wfe_engine.launch("process7")
   rescue Exception => e
     assert e.message=='unknown process', "bad message caught: #{e.message}"
   end

   end
end
