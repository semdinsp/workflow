package com.ficonab;
import javax.jms.MessageListener;
import com.ficonab.FiconabBase;


//@MessageDriven(mappedName = "workflow")
public class WorkflowBean extends FiconabBase  implements MessageListener {
		public  String get_topic() { return "workflow"; }
	public String get_bootstrap_string() {
	String bootstrap_string = "gem 'workflow_manager'; require 'workflow_manager'; WorkflowManager::WorkflowServer.new({:topic => 'workflow', :jms_source => 'workflowserver'})"; 
	    return bootstrap_string;
	}
	

}