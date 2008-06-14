
Testing:


stomp_message_send.rb -T '/topic/workflow' -M stomp_WORKFLOW -b process

stomp_message_send.rb -T '/topic/workflow' -M stomp_WORKFLOW -H '{ :process => "balance_transfer", "debit_msisdn" =>  "639993130030", "credit_msisdn" => "639993130313", "peso_value" => "23" }' -A true

pasaload test:
stomp_message_send.rb -T '/topic/workflow' -M stomp_WORKFLOW -H '{ :process => "pasaload", "source_msisdn" =>  "639993130255", "dest_msisdn" => "639993130259", "peso_value" => "3" }' -A true


balance_inquiry test:
stomp_message_send.rb -T '/topic/workflow' -M stomp_WORKFLOW -H '{ :process => "balance_inquiry", "source_msisdn" =>  "639993130255", "dest_msisdn" => "639993130259", "peso_value" => "3" }' -A true

jms_message_send.rb -T workflow -M stomp_WORKFLOW -H '{ :process => "balance_inquiry", "source_msisdn" =>  "639993130255", "dest_msisdn" => "639993130259", "peso_value" => "3" }' -A true
README

JMS
Building Message Bean:
cp ../stomp_message/build/com/ficonab/*.class build/com/ficonab/
javac -cp $JRUBY_HOME/lib/jruby.jar:$GLASSFISH_ROOT/lib/j2ee.jar:./build -d build com/ficonab/WorkflowBean.java
cd build
jar cf ../workflowbean.ear .
cd ..
asadmin deploy workflowbean.ear
asadmin deploy --host svbalance.cure.com.ph --port 2626 workflowbean.ear


OLD
jar cf ../workflowbean.ear .
cp workflowbean.jar ../../glassfish/domains/domain1/autodeploy/


NEED MYSQL DRIVER IN CLASSPATH
CLASSPATH:
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/j2ee.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/appserv-rt.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/javaee.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/j2ee-svc.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/appserv-ee.jar
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/activation.jar
export CLASSPATH=$CLASSPATH:/Users/scott/Documents/ror/glassfish/lib/dbschema.jar 
export CLASSPATH=$CLASSPATH:/Users/scott/Documents/ror/glassfish/lib/appserv-admin.jar 
export CLASSPATH=$CLASSPATH:/Users/scott/Documents/ror/glassfish/lib/install/applications/jmsra/imqjmx.jar   
export CLASSPATH=$CLASSPATH:/Users/scott/Documents/ror/glassfish/lib/install/applications/jmsra/imqjmsra.jar
 export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/imq/lib/fscontext.jar

Mysql class path
export CLASSPATH=$CLASSPATH:$GLASSFISH_ROOT/lib/mysql-connector-java-5.0.8-bin.jar