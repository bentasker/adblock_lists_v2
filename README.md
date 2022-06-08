Adblock lists V2
===================

I used to build a range of Adblock lists, including a modified version of the Easylist ad blocking list.

However it wasn't really feasible to continue publishing and maintaining those lists (more information in [jira-projects/ADBLK#1](https://projects.bentasker.co.uk/gils_projects/project/jira-projects/1.html)) so this set of lists was born.

----

### Usage

To use the blocklists, you should use one of the following URLS

- https://raw.githubusercontent.com/bentasker/adblock_lists_v2/master/lists/adblock_plus.txt
- https://raw.github.com/bentasker/adblock_lists_v2/master/lists/unbound.txt
- https://raw.github.com/bentasker/adblock_lists_v2/master/lists/blockeddomains.txt
- https://raw.github.com/bentasker/adblock_lists_v2/master/lists/regexes.txt
- https://raw,github.com/bentasker/adblock_lists_v2/master/lists/zones.txt

Which URL will obviously depend on which system you're having consume

If you're using [`pihole`](https://pi-hole.net/) then you'll want to use `blockeddomains.txt` and might also want to [configure Pi-Hole to update blocklists more regularly](https://www.bentasker.co.uk/posts/blog/privacy/467-configuring-pi-hole-to-update-blocklists-more-regularly.html)

----

### Block Lists

The `list` directory in this repository contains more or less a single adblock list published in a number of different formats formats

- [`adblock_plus.txt`](https://raw.githubusercontent.com/bentasker/adblock_lists_v2/master/lists/adblock_plus.txt): Adblock Plus and UBlock Origin compatible format
- [`unbound.txt`](https://raw.github.com/bentasker/adblock_lists_v2/master/lists/unbound.txt): Unbound config compatible format
- [`blockeddomains.txt`](https://raw.github.com/bentasker/adblock_lists_v2/master/lists/blockeddomains.txt): A simple list of Blocked domains
- [`regexes.txt`](https://raw,github.com/bentasker/adblock_lists_v2/master/lists/regexes.txt): A list of zone wide blocks
- [`zones.txt`](https://raw,github.com/bentasker/adblock_lists_v2/master/lists/zones.txt): A list of zone wide blocks

The list of blocked zones can be used with a parser to [generate regexes to feed into PiHole](https://github.com/bentasker/adblocklists/blob/master/bin/pihole_apply_regexes.sh).


----

### Config Files

The blocklists are built based upon files within the `config` directory

- `manualpages.txt`: full URLs, will be included in the ABP lists. If a domain is specified with no path/args then it'll generate a zone-wide block too
- `manualzones.txt`: DNS zones to block. Anything listed here will have every subdomain of it blocked (where possible)
- `manualblocks/*` : directory of domain names to block - seperate files can be used to maintain a semi-logical order
- `regexes/*`: a directory of regexes to block - seperate files can be used to maintain a semi-logical order


----

### Hooks

The lists are updated via git hooks, so when first cloning the repo down it's necessary to run

    hooks/post-merge
    
The hooks should be self-maintaining after that.


License
--------

Lists and scripts are licensed under the [BSD 3 Clause License](http://opensource.org/licenses/BSD-3-Clause) and are Copyright (C) 2022 [Ben Tasker](https://www.bentasker.co.uk)
