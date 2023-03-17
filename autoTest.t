#charset "us-ascii"
#include <adv3.h>
#include <en_us.h>

// Module ID for the library
autoTestModuleID: ModuleID {
        name = 'Auto Test Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// Implement a command that produces no effect other than outputting
// an empty string.
// We use this as a sort of NOP for advancing the turn without adding
// a bunch of repetitive "Time passes..." messages like using >WAIT would.
DefineIAction(AutoTestWait)
	execAction() {
		gActor.autoTestMain();
		defaultReport('');
	}
;
VerbRule(AutoTestWait) 'handsfreewait': AutoTestWaitAction
	verbPhrase = 'handsfreewait/handsfreewaiting';

// An actor class for the "player" in an automated test script.  Instead
// of waiting for player input or reading commands from a file, by default
// we just silently advance the turn counter by invoking the AutoTestWait
// action we defined above.
class AutoTestActor: Actor
	// The maximum number of turns to run before exiting.
	// Can be set to -1 to run indefinitely.  BE SURE TO DEFINE SOME
	// OTHER EXIT CONDITION IF YOU DO THIS.
	autoTestMaxTurns = 100

	// Optional output file name.  If defined, we'll write the transcript
	// to the given file.
	autoTestScriptName = nil

	// If defined, we'll call autoTestCheckpoint() every this many turns.
	// By default autoTestCheckpoint() just outputs the turn number,
	// but this can be changed to output whatever debugging information
	// you want in the transcript.
	autoTestCheckpointInterval = nil

	// If defined, we'll prefix our debugging output with this
	// string.  By default this is only used for the timestamps if
	// we've been asked to output them.
	autoTestDebugPrefix = 'autoTest: '

	// The number of turns we've taken.  We don't just use
	// libGlobal.totalTurns because some actions won't advance the
	// global turn count, and there's no guarantee that others won't
	// advance it by more than one at a time.
	_autoTestTurnCounter = 0

	// Convenience method to return our current turn number.
	getAutoTestTurn() { return(_autoTestTurnCounter); }

	// Main entry point for our logic.  This is called as part of
	// normal adv3 processing.
	executeTurn() {
		// See if we need to start outputting the transcript.
		if(_autoTestTurnCounter == 0)
			autoTestStartScript();

		// Call our custom wait action.
		autoTestWait();
	}

	// Invoke our wait command.  This will output a zero-length
	// default report and then call autoTestMain().  We do it
	// this way so that our autoTestTurn() method gets called
	// "inside" the action.  executeTurn() would otherwise be
	// called "before" the action, which makes it slightly more
	// confusing to synchronize turn numbers and so on.
	autoTestWait() { newActorAction(self, AutoTestWait); }


	// Called by the AutoTestWait action.
	autoTestMain() {
		_autoTestCheckpoint();

		autoTestTurn();

		_autoTestCounter();
	}

	// Advance the turn counter.
	_autoTestCounter() {
		_autoTestTurnCounter += 1;

		// See if we're supposed to exit after a certain number
		// of turns.  If not, we're done.
		if(autoTestMaxTurns == nil)
			return;

		// See if we need to stop the game.
		if(_autoTestTurnCounter >= autoTestMaxTurns)
			autoTestExit();
	}

	// Logging function.  By default it's only used for timestamps,
	// but can be used by whatever happens in autoTestTurn().
	autoTestLog(msg) {
		aioSay('\n<<(autoTestDebugPrefix ? autoTestDebugPrefix : '')>>'
			+ msg + '\n ');
	}

	// Output a "timestamp" if we've been asked to.
	_autoTestCheckpoint() {
		if(autoTestCheckpointInterval == nil)
			return;
		if(_autoTestTurnCounter % autoTestCheckpointInterval)
			return;
		autoTestCheckpoint();
	}

	// "Timestamp" method that outputs the number of times we've
	// run and the global turn number.
	autoTestTimestamp() {
		autoTestLog('auto test turn
			<<toString(_autoTestTurnCounter)>>, global turn
			<<toString(libGlobal.totalTurns)>>');
	}

	// Start logging to the script file, if one is defined.
	autoTestStartScript() {
		if(autoTestScriptName == nil)
			return;
		executeCommand(self, self, cmdTokenizer.tokenize('script "'
			+ toString(autoTestScriptName) + '"'), true);
	}

	// Checkpoint method called every autoTestCheckpointInterval
	// turns.  By default we just output the turn numbers.
	autoTestCheckpoint() { autoTestTimestamp(); }

	// Stub method, does nothing.  This is where your per-turn
	// logic should go.
	autoTestTurn() {}

	autoTestExit() {
		autoTestLog('Exiting after <<toString(_autoTestTurnCounter)>>
			turns.');
		autoTestEnd();
	}
	// Throw an exception, ending the game.
	autoTestEnd() { throw new QuittingException(); }
;
