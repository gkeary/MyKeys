# Copyright (C) 2001, 2002  Earnie Boyd  <earnie@users.sf.net>
# This file is part of the Minimal SYStem.
#   http://www.mingw.org/msys.shtml
#
#         File:	profile
#  Description:	Shell environment initialization script
# Last Revised:	2002.05.04

# try vi
set -o vi

if [ -z "$MSYSTEM" ]; then
  MSYSTEM=MINGW32
fi

# My decision to add a . to the PATH and as the first item in the path list
# is to mimick the Win32 method of finding executables.
#
# I filter the PATH value setting in order to get ready for self hosting the
# MSYS runtime and wanting different paths searched first for files.
if [ $MSYSTEM == MINGW32 ]; then
  export PATH=".:/usr/local/bin:/mingw/bin:/bin:$PATH"
else
  export PATH=".:/usr/local/bin:/bin:/mingw/bin:$PATH"
fi

# check msys-1.0.dll
if test -f /etc/msys-1.0.dll.md5
then
	# if check succeeds, let's avoid checking again
	test "$(md5sum /bin/msys-1.0.dll)" = "$(cat /etc/msys-1.0.dll.md5)" &&
	rm -f /etc/msys-1.0.dll.md5 ||
	printf "\n\033[31mERROR: Your msys-1.0.dll is out-of-date!\033[m\n\n"
fi

if [ -z "$USERNAME" ]; then
  LOGNAME="`id -un`"
else
  LOGNAME="$USERNAME"
fi

# Set up USER's home directory
if [ -z "$HOME" -o ! -d "$HOME" ]; then
  HOME="$HOMEDRIVE$HOMEPATH"
fi

if [ ! -d "$HOME" ]; then
	printf "\n\033[31mERROR: HOME directory '$HOME' doen't exist!\033[m\n\n"
	echo "This is an error which might be related to msysGit issue 108."
	echo "You might want to set the environment variable HOME explicitely."
	printf "\nFalling back to \033[31m/ ($(cd / && pwd -W))\033[m.\n\n"
	HOME=/
fi

# normalize HOME to unix path
HOME="$(cd "$HOME" ; pwd)"

export PATH="$HOME/bin:$PATH"

export GNUPGHOME=~/.gnupg

if [ "x$HISTFILE" == "x/.bash_history" ]; then
  HISTFILE=$HOME/.bash_history
fi

if [ -e ~/.inputrc ]; then
    export INPUTRC=~/.inputrc
else
    export INPUTRC=/etc/inputrc
fi

export HOME LOGNAME MSYSTEM HISTFILE

for i in /etc/profile.d/*.sh ; do
  if [ -f $i ]; then
    . $i
  fi
done

export MAKE_MODE=unix

# Git specific stuff
test -e /bin/git.exe -o -e /git/git.exe || {
	echo
	echo -------------------------------------------------------
	echo "Building and Installing Git"
	echo -------------------------------------------------------

	cd /git &&
	make install

	case $? in
	0)
		MESSAGE="You are in the git working tree, and all is ready for you to hack."
	;;
	*)
		MESSAGE="Your build failed...  Please fix it, and give feedback on the Git list."
	esac

	test -d /installer-tmp && rm -rf /installer-tmp

	cat <<EOF


-------------------------
Hello, dear Git developer.

This is a minimal MSYS environment to work on Git.

$MESSAGE

EOF
}

# let's make sure that the post-checkout hook is installed
test -d /.git && test ! -x /.git/hooks/post-checkout &&
test -x /share/msysGit/post-checkout-hook &&
mkdir -p /.git/hooks &&
cp /share/msysGit/post-checkout-hook /.git/hooks/post-checkout

test -f /etc/motd && sed "s/\$MESSAGE/$MESSAGE/" < /etc/motd
test -x /share/msysGit/initialize.sh -a ! -d /.git &&
cat << EOF

It appears that you installed msysGit using the full installer.
To set up the Git repositories, please run /share/msysGit/initialize.sh
EOF

case ":$PATH:" in
*:/cmd:*|*:/bin:*) ;;
*)
	cat << EOF

In order to use Git from cmd.exe:
1. Add c:\msysgit\cmd to cmd's PATH
2. DON'T add c:\msysgit\bin or c:\msysgit\mingw\bin to cmd's PATH
Commands like 'git add' will work from cmd.exe now.
Commands like 'git-add' will NOT work. Add more wrappers as appropriate.
EOF
esac


. /etc/git-completion.bash
# removed this because colors suck rgk 10/26/09
#PS1='\[\033]0;$MSYSTEM:\w\007
#\033[32m\]\u@\h \[\033[33m\w$(__git_ps1)\033[0m\]
#$ '
@SUSE prompt   see: http://www.gilesorr.com/bashprompt/prompts/suse.html
PS1="\u@\h:\w/ > "
PS2="> "

# set default options for 'less'
export LESS=-FRSX
# set default protocol for 'plink'
export PLINK_PROTOCOL=ssh

# read user-specific settings, possibly overriding anything above
if [ -e ~/.bashrc ]; then
    . ~/.bashrc
elif [ -e ~/.bash_profile ]; then
    . ~/.bash_profile
elif [ -e /etc/bash_profile ]; then
    . /etc/bash_profile
fi

#start up pageant.exe
/c/putty/pageant.exe
echo "add the private key or "
echo "git push will not work"
