#!/bin/bash

#  File:     pbs_status.sh
#
#  Author:   David Rebatto
#  e-mail:   David.Rebatto@mi.infn.it
#
#
#  Revision history:
#    20-Mar-2004: Original release
#    04-Jan-2005: Totally rewritten, qstat command not used anymore
#
#  Description:
#    Return a classad describing the status of a PBS job
#
#
#  Copyright (c) 2004 Istituto Nazionale di Fisica Nucleare (INFN).
#  All rights reserved.
#  See http://grid.infn.it/grid/license.html for license details.
#

logpath=/var/spool/pbs/server_logs

pars=$*
requested=`echo $pars | sed -e 's/^.*\///'`
logfile=`echo $pars | sed 's/\/.*//'`
logs="$logpath/$logfile `find $logpath -type f -newer $logpath/$logfile`"

result=`awk -v jobId=$requested '
BEGIN {
	rex_queued   = jobId ";Job Queued "
	rex_running  = jobId ";Job Run "
	rex_deleted  = jobId ";Job deleted "
	rex_finished = jobId ";Exit_status="
	rex_hold     = jobId ";Holds "

	print "["
	print "BatchjobId = \"" jobId "\";"
}

$0 ~ rex_queued {
	jobstatus = 1
}

$0 ~ rex_running {
	jobstatus = 2
}

$0 ~ rex_deleted {
	jobstatus = 3
	exit
}

$0 ~ rex_finished {
	jobstatus = 4
	s = substr($0, index($0, "Exit_status="))
	s = substr(s, 1, index(s, " ")-1)
	exitcode = substr(s, index(s, "=")+1)
	exit
}

$0 ~ rex_hold {
	jobstatus = 5
}

END {
	if (jobstatus == 0) { exit 1 }
	print "JobStatus = " jobstatus ";"
	if (jobstatus == 4) {
		print "ExitCode = " exitcode ";"
	}
	print "]"
}
' $logs`

if [ "$?" == "0" ] ; then
	echo $result
	retcode=0
else
	echo "ERROR: Job not found"
	retcode=1
fi

exit $retcode
