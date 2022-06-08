#!/bin/bash
#
# Build the output lists
#
# First added in jira-projects/ADBLK#1

function blockdomain(){
    domain=$1
    echo "$domain" >> $blocked_doms


    # Check if the domain exists within a zone that'll be blocked
    egrep -v -e "^${domain#*.}|^$domain" $blocked_zones > /dev/null
    if [ "$?" == "1" ]
    then
        echo "local-data: \"$domain A 127.0.0.1\"" >> $unbound_listbuild
        echo "local-data: \"$domain AAAA ::1\"" >> $unbound_listbuild
    fi
}



# Create a temporary file for each of the lists

# Compiled temporary domain list
domain_listtmp=`mktemp`

# Unbound format
unbound_listbuild=`mktemp`

# Domain list
blocked_doms=`mktemp`

# Blocked Zones (TODO)
blocked_zones=`mktemp`

# ABP (TODO)
abp=`mktemp`



for blockfile in config/manualblocks/*txt 
do
    cat $blockfile | egrep -v -e '^#|^$' | while read -r domain
    do
        echo "$domain" >> $domain_listtmp
    done
done



cat $domain_listtmp | sort | uniq | egrep -v -e '^$' | while read -r domain
do
    blockdomain $domain
done


cat << EOM

============== List===========
`cat $domain_listtmp`


============== Unbound ===========
`cat $unbound_listbuild`


EOM
