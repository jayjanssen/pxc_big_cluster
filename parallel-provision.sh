#!/bin/bash


node_list=($(vagrant status | grep running | awk '{print $1}'))

for (( i = 0 ; i < ${#node_list[@]} ; i++ ))
do    
    node=${node_list[$i]}

	echo "Provisioning $node"
	vagrant provision $node &
done

for job in `jobs -p` 
do
	echo $job
	wait $job || let "FAIL+=1"
done

echo "$FAIL failed!"
