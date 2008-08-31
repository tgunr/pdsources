#!/bin/bash
#  install
#
# Installs scripts in this folder to your $HOME/bin folder
#  Created by Dave Carlton on 2008-08-02.
#  Copyright (c) 2008 polyMicro Systems. All rights reserved.
#
CMDPATH="`dirname "$0"`"

# See if user has a bin folder
if [[ -d ~/bin ]] ; then
	rsync -auv --exclude="install.sh" --exclude=".*" "$CMDPATH" ~/bin

	set()					# set -s for set command without functions
	{
	    if [ "$1" = "+x" ] || [ "$1" = "-x" ]; then
	    	builtin set "$@"		# intercepting +x and -x makes shorter trace
	    	return				# if -x is currently enabled
	    fi
    
	    if [ "$1" != "-s" ] && [ "$1" != "--s" ]; then
	    	builtin set "$@"		# anything else goes to builtin set command
	    	return
	    fi
    
	    if [ $# != 1 ]; then
	    	builtin set "$@"
	    	return
	    fi
    
	    local __m__
	    declare -i __n__
    
	    set | sed -e '/^__m__=$/D;/^__n__=/D' >/tmp/set.$$ # dont' show our locals
    
	    # Find out the line number of the first finction so we can list up to that point.
    
	    __n__=`sed -e '/^[{]/=;/^[^{]/D;/^[{]/q' </tmp/set.$$ | sed -e 's/[{]//'`
	    let __n__=$__n__-2
    
	    head -n $__n__ /tmp/set.$$
    
	    command rm -f /tmp/set.$$
	}

	#insure user has ~/bin in PATH, if not put it into the startup file
	set -s|grep "^PATH="|grep "$HOME/bin:"
	if [[ $? != 1 ]] ; then
		echo 'PATH=$HOME/bin:$PATH' >> "$HOME/.bash_profile"
		export PATH=$HOME/bin:$PATH
	fi

fi
