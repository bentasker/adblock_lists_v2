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

function blockDomains(){
    # Process the block files
    
    echo "- Domain Lists"
    
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
}

function buildRegexes(){
    # Combine the regex config

    cat config/regexes/*txt | sort | uniq > $regex_blocks
}

function buildZoneList(){
    # Build the zones derived lists
    
    echo "- Zone Lists"
    
    # Take the manualzones
    cat config/manualzones.txt | egrep -v -e '^#' | while read -r domain
    do
        echo "$domain" >> $blocked_zones
    done

    # Check for any domains blocked in manualpages (i.e. no variables and no path specified)
    egrep -v -e '/|\$' config/manualpages.txt | egrep -v -e '^#' | sed 's/www\.//g' | while read -r domain
    do
        echo "$domain" >> $blocked_zones
    done
    
    # Take the list of blocked zones and turn it into unbound format
    cat $blocked_zones | sort | uniq | egrep -v -e '^$' | while read -r domain
    do
        echo "local-zone: \"$domain\" redirect" >> $unbound_listbuild
        echo "local-data: \"$domain A 127.0.0.1\"" >> $unbound_listbuild
    done
}


function buildABP(){
# Generate an ABP compatible list
echo "- ABP"

DATE=`date +'%Y%m%d%H%M'`
DATE_FULL=`date`

cat << EOM > $abp
[Adblock Plus 2.0]
! Version: $DATE
! Title: B Tasker
! Last modified: $DATE_FULL
! Expires: 4 days (update frequency)
! Homepage: https://projects.bentasker.co.uk/gils_projects/project/jira-projects/ADBLK.html
! Licence: https://www.bentasker.co.uk/licensedetails
! 
! Basically a list of ad domains that have snuck past my more traditional filters at one point or another
! 
! -----------------------General advert blocking filters-----------------------!
! *** btasker:adblock/adblock_compiled_v2.txt ***
EOM

cat config/manualblocks/*.txt | egrep -v -e '^#|^$' | sed -e 's/^/||/' | sed -e 's/$/^*/' >> $abp
cat config/manualzones.txt | egrep -v -e '^#|^$' | sed -e 's/^/||*./' | sed -e 's/$/^*/' >> $abp
cat config/manualpages.txt | egrep -v -e '^#|^$' | sed -e 's/^/||/'  >> $abp

}


### Main ####


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
 
# Regexes
regexes=`mktemp`

echo "Building lists"
# Build the block lists
buildZoneList
blockDomains
buildABP
buildRegexes

# Finally, install the files
echo
echo "Installing:"

echo "- blockeddomains.txt"
cat $domain_listtmp | sort | uniq > lists/blockeddomains.txt

echo "- zones.txt"
cat $blocked_zones | sort | uniq > lists/zones.txt # used to be manualzones.txt

echo "- unbound.txt"
mv $unbound_listbuild lists/unbound.txt # used to be autolist.txt

echo "- adblock_plus.txt"
mv $abp lists/adblock_plus.txt

echo "- regexes"
mv $regex_blocks lists/regexes.txt
