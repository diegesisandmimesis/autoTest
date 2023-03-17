#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// Noninteractive demo of the autoTest logic.  This'll just run for
// ten turns and then exit.
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
// We define me to be an instance of the AutoTestActor class.
+me: AutoTestActor
	// Exit after ten turns.
	autoTestMaxTurns = 10

	// Output the "timestamp" every five turns.
	autoTestCheckpointInterval = 5
;
// Add an NPC to who'll generate some output every turn.
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
