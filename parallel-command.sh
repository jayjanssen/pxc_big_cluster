#!/bin/bash


echo "Running '$*' on all nodes"

node_list=($(vagrant status | grep running | awk '{print $1}'))

for (( i = 0 ; i < ${#node_list[@]} ; i++ ))
do    
    node=${node_list[$i]}

	echo "Running '$*' on $node"
	vagrant ssh $node -c "$*" &
done

for job in `jobs -p` 
do
	echo $job
	wait $job || let "FAIL+=1"
done

echo "$FAIL failed!"
