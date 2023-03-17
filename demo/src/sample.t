#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the autoTest library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "autoTest.h"

startRoom: Room 'Void' "This is a featureless void.";
+me: AutoTestActor
	// Exit after ten turns.
	autoTestMaxTurns = 10

	// Output the "timestamp" every five turns.
	autoTestCheckpointInterval = 5
;
+alice: Person 'Alice' 'Alice'
	"She looks like the first person you'd turn to in a problem. "
	isProperName = true
	isHer = true
;
++AgendaItem
	initiallyActive = true
	isReady = true
	invokeItem() {
		defaultReport('Alice announces, <q>Turn
			<<spellInt(libGlobal.totalTurns)>> and all is
			well.</q>');
	}
;

versionInfo:    GameID;
gameMain:       GameMainDef initialPlayerChar = me;
