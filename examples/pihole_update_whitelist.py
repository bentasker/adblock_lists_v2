#!/usr/bin/env python3
#
# Download white list and write into Pi-Hole's gravity DB
#
# Implemented for jira-projects/ADBLK#4
#
# For an example of how to deploy this script, see 
# See https://www.bentasker.co.uk/posts/documentation/general/refreshing-piholes-regex-block-list-from-external-sources.html#installation
#
'''
License: BSD 3-Clause

Copyright 2022 B Tasker

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'''

import hashlib
import os
import requests
import subprocess
import sqlite3
import sys


restart_cmd = ["pihole", "restartdns", "reload-lists"]

def fetchList(url):
    ''' Fetch a text file and return a list of lines
    '''
    r = requests.get(url)
    return r.text.split("\n")
    
    
def writeEntries(domain_list,comment):
    ''' Write exact whitelist entries into the gravity database
    '''
    conn = sqlite3.connect("/etc/pihole/gravity.db")
    c = conn.cursor()

    c.execute('DELETE FROM domainlist WHERE comment=?',(comment,))
    c.executemany('INSERT OR IGNORE INTO domainlist (type, domain, comment, enabled) '
                    'VALUES (0, ?, ?, 1)',
                    [(x, comment) for x in sorted(domain_list)])
                    
    conn.commit()
    
# Fetch the whitelist
whitelist = fetchList('https://raw.githubusercontent.com/bentasker/adblock_lists_v2/master/lists/alloweddomains.txt')

# Remove empty lines and sort
merged = list(filter(None, whitelist))
whitelist.sort()

# Convert to a string so that we can hash it to check for changes
mergedstr = "\n".join(whitelist)



# Calculate a SHA1
sha1 = hashlib.sha1()
sha1.update(mergedstr.encode('utf-8'))
merged_sha = sha1.hexdigest()

# Initialise for later
cache_sha1 = ""

# Read the cachefile if it exists
if os.path.exists("/etc/pihole/allow_list_cache"):
    with open("/etc/pihole/allow_list_cache") as f:
        cache = f.read()
        sha1 = hashlib.sha1()
        sha1.update(cache.encode('utf-8'))
        cache_sha1 = sha1.hexdigest()
    
# Has the list changed?
if cache_sha1 != merged_sha:
    writeEntries(whitelist, 'bentasker/adblock_lists_v2/allowlist')
    fh = open("/etc/pihole/allow_list_cache", "w")
    fh.write(mergedstr)
    fh.close()
    
    # Restart pihole-FTL
    subprocess.run(restart_cmd, stdout=subprocess.DEVNULL)
    
    # Signal that a change was made
    sys.exit(0)
else:
    # Signal that no change occurred
    sys.exit(2)
