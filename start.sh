#!/bin/bash

ID_defined=false
show_help=false

forwarded_IP_array=()
conpot_pc_array=()
protocols_array=()
protocols_port_array=()
forward_array=()

while read line; do
if [[ "$line" != "#"* ]]; then

	IFS='=' read -a lineArray <<< "$line"
	case ${lineArray[0]} in
	    conpotPC)
	    IFS=':' read -a pcArray <<< "${lineArray[1]}"
	    forwarded_IP_array+=("${pcArray[1]}")
	    conpot_pc_array+=("${pcArray[0]}")
	    ;;

	    protocol)
	    IFS=':' read -a protocolArray <<< "${lineArray[1]}"
	    protocols_port_array+=("${protocolArray[1]}")
	    protocols_port_default_array+=("${protocolArray[1]}")
	    protocols_array+=("${protocolArray[0]}")
	    ;;

	    forward)
	    forward_array+=("${lineArray[1]}")
	    ;;

	    interfaceIn)
	    interfaceIn="${lineArray[1]}"
	    ;;

	    interfaceOut)
	    interfaceOut="${lineArray[1]}"
	    ;;

	    template)
	    conpotTemplate="${lineArray[1]}"
	    ;;

	esac

fi
done <conpotImunes.conf
### read the arguments given with start.sh

while [[ $# -ge 1 ]]
do
key="$1"

case $key in
    -e)
    ID="$2"
    ID_defined=true
    shift # past argument
    ;;

    -b)
    topology="$2"
    topology_file_defined=true
    shift # past argument
    ;;

    -h|--h|--help)
    show_help=true
    ;;
    *)
            # unknown option
    ;;
esac

shift # past argument or value
done

### show the help message or execute the topology startup

if [ "$show_help" = true ] || [ "$topology_file_defined" = false ] ; then

	echo 'Use start.sh to start a topology with conpot nodes:

	-b [imunes_file]    define topology file : this is mandatory!
	-e [preffered_ID]   use specific ID for imunes topology
	-h,--h,--help       show this message

	Use "sudo cleanupAll" to end execution
'

else

	######## start imunes topology ########
	# The imunes experiment is executed with a manualy choosen ID or a random ID
	# "sudo cleanupAll" can later be used to stop the execution 

	if [ "$ID_defined" = true ] ; then
		sudo imunes -e $ID -b $topology
	else
		sudo imunes -b $topology	
	fi

	######### Route to subnet ##########
	# route to 10.0.0.0 subnet through  virtual router's interface  that is 
	# connected to the external connection node

	ip route add 10.0.0.0/16 via "$interfaceIn"
	echo "$interfaceIn"
	echo "$interfaceOut"
	echo "$conpotTemplate"

	######### Packet forwarding ##########
	# packets are forwarded to and from eth0 interface to the virtual network

	iptables -t nat -A POSTROUTING -o $interfaceOut -j MASQUERADE

	iptables -A FORWARD -i $interfaceOut -d 10.0.0.0/16 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -s 10.0.0.0/16 -o $interfaceOut -j ACCEPT

	######### DNS server IP address ##########
	# use nm-tool to fetch host-s dns server, 
	# write it in the resolv.conf and
	# copy resolv.conf to virtual nodes

	nm-tool | grep DNS > resolv.conf

	sed -i 's/DNS:/nameserver/' resolv.conf
	sed -i 's/^[ \t]*//' resolv.conf


	for i in ${conpot_pc_array[*]};
	do

		echo "$i"
		######### DNS server IP address ##########
		# resolv.conf contains the IP address of a DNS server and is copied to the 
		# ect folder to the virtual nodes

		hcp resolv.conf $i:/etc/

		### modify default conpot configuration ports
		for j in "${!protocols_port_array[@]}";
		do 
			himage "$i" sed -i "s/port=\"${protocols_port_default_array[$j]}\"/port=\"${protocols_port_array[$j]}\"/" /usr/local/lib/python2.7/dist-packages/conpot/templates/"$conpotTemplate"/"${protocols_array[$j]}"/"${protocols_array[$j]}".xml
			
			#increase ports by 1
			protocols_port_array[$j]=$((${protocols_port_array[$j]}+1))
		done
		

		######### Start Srevices ##########
		# start postfix, conpot and osssec

		himage "$i" /etc/init.d/postfix start >/dev/null 2>&1 &

		himage "$i" conpot -l /etc/conpot.log --template "$conpotTemplate" >/dev/null 2>&1 &

		himage "$i" /var/ossec/bin/ossec-control restart >/dev/null 2>&1 &
		

	done

	outIP=`ip addr show eth0 | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}'`
	echo "$outIP"

	for i in ${forwarded_IP_array[*]};
	do 
		for j in "${!forward_array[@]}";
		do 

		echo "$i : ${forward_array[$j]} --> $outIP : ${forward_array[$j]}"
		iptables -t nat -A PREROUTING -p tcp -d "$outIP" --dport "${forward_array[$j]}" -j DNAT --to-destination "$i":"${forward_array[$j]}"

		forward_array[$j]=$((${forward_array[$j]}+1))

		done

	done

fi
