modified vroot imunes with conpot
=================================

This repository can be used to create Imunes nodes with Conpot, Postfix and OSSEC installed.
There is also a start.sh script included that can be used to initialize a topology of Conpot nodes and
a CollectLogs.sh script that can be used to fetch conpot.log files from a virtual nodes.

Prerequisites:
--------------

Imunes installed and forwarding enabled on the system.

Virtual node modification
-------------------------

Run the makeConpotNode.sh with: 

	$ cd vroot-linux/

	vroot-linux$ sudo bash makeConpotNode.sh user-gmail user-password

Where user-gmail and user-password is the gmail address you want to recieve notifications to and it's password.


Network initialization
----------------------

	vroot-linux$ sudo bash start.sh -b imunestopology

imunestopology is the topology file from Imunes that you want to execute. To configure the network make changes to the conpotImunes.conf file. 
The test1.imn file can be used to make a simple network without making any modifications to the configuration file with:

	vroot-linux$ sudo bash start.sh -b test1.imn


Log collection
--------------

A conpot.log file can be fetched from a node with:

	vroot-linux$ sudo bash collectLogs.sh node-name

where node-name is the node you want to fetch the log from.

