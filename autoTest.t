#charset "us-ascii"
//
// autoTest.t
//
// This provides a simple mechanism for "hands off" testing of TADS3
// code.  Instead of prompting the player for a command every turn, by
// default the turn counter will just automatically advance for a set
// number of turns.
//
//
// DECLARING TESTS
//
//	// Declares a new test instance
//	AutoTest
//		autoTestMaxTurns = 10
//	;
//
// This will cause the game to automagically run for ten turns and then
// exit.
//
//
// METHODS/PROPERTIES TO CHANGE
//
//	autoTestMaxTurns		The number of turns to run before
//					exiting. This can be nil, in which
//					case the game will run indefinitely.
//					If you do this you'll want to
//					want to also declare a autoTestTurn()
//					method that implements some other exit
//					condition.
//	autoTestTurn()			A method that will be called every turn.
//	autoTestCheckpoint()		A method that will be called every
//					autoTestCheckpointInterval turns.  By
//					default it outputs the number of times
//					the autoTest logic has run and the
//					global turn number.
//	autoTestCheckpointInterval	If non-nil, autoTestCheckpoint() will
//					be called every this many turns.  So
//					if this is 10, it will be called every
//					ten turns, if it's 2 it will be called
//					every other turn, and so on.
//	autoTestScriptName		If non-nil, log the transcript to the
//					named file.
//
// UTILITY METHODS
//
//	autoTestEnd()			Exit the game
//	autoTestLog(msg)		Outputs the given message, prefixed
//					with autoTestDebugPrefix ('autoTest: '
//					by default.  Just to make it easier
//					to spot autoTest-related messages
//					in the transcript.
//	autoTestTimestamp()		Logs the autoTest turn count and the
//					global turn count.  Those will start
//					out the same, but there's no guarantee
//					that they'll stay in sync (because
//					actions can change the global turn by
//					one, zero, or more than one).
//
//
// TURN LIFECYCLE
//
//	This is a quick summary of the auto test turn lifecycle.
//
//	In general, the "gimmick" is that we overwrite a couple methods
//	on the default player character to call corresponding methods
//	on autoTestManager, then autoTestManager in turn calls methods
//	on the declared test instance.
//
//	The reasons for jumping through all these hoops (calling a method
//	that calls a method that calls a method) are:  a) wanting to
//	provide a method that allows for standalone test declarations, and
//	b) to be able to write test methods that will be executed in
//	the "middle" of a turn (during command execution, instead of before
//	or after it).
//
//		gPlayerChar.executeTurn()
//			Called automagically by adv3 at the start of each
//			turn.  At preinit we overwrite this method on
//			the actor object, to call autoTestManager.executeTurn()
//
//		autoTestManager.executeTurn()
//			Called by gPlayerChar.executeTurn() at the start of
//			each turn.  This calls the declared AutoTest instance's
//			executeTurn() and then replaces the current turn's
//			action with a custom wait action.
//
//		AutoTest.executeTurn()
//
//		AutoTestWaitAction.execAction()
//
//		gPlayerChar.autoTestMain()
//
//		autoTestManager.autoTestMain()
//
//		AutoTest.autoTestMain()
//
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

// An actor class for the "player" in an automated test script.  Instead
// of waiting for player input or reading commands from a file, by default
// we just silently advance the turn counter by invoking the AutoTestWait
// action we defined above.
class AutoTest: object
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
		if(_autoTestTurnCounter == 0) {
			autoTestStartScript();
			autoTestStartGame();
		}
	}

	autoTestStartGame() {}

	// Called by the AutoTestWait action.
	autoTestMain() {
		_autoTestCheckpoint();

		autoTestTurn();

		_autoTestCounter();
	}

	// Advance the turn counter.
	_autoTestCounter() {
		// If we're not running for a set number of turns,
		// just increment the counter and return.
		if(autoTestMaxTurns == nil) {
			_autoTestTurnCounter += 1;
			return;
		}

		// If we're here, we're going to stop the game at some
		// point, so check to see if that point is now.
		if(_autoTestTurnCounter >= autoTestMaxTurns)
			autoTestExit();

		// Nope, just increment the turn counter.
		_autoTestTurnCounter += 1;
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
		executeCommand(gActor, gActor,
			cmdTokenizer.tokenize('script "'
			+ toString(autoTestScriptName) + '"'), true);
	}

	// Checkpoint method called every autoTestCheckpointInterval
	// turns.  By default we just output the turn numbers.
	autoTestCheckpoint() { autoTestTimestamp(); }

	// Stub method, does nothing.  This is where your per-turn
	// logic should go.
	autoTestTurn() {}

	// Log a brief report and exit.
	autoTestExit() {
		autoTestLog('Exiting after <<toString(_autoTestTurnCounter)>>
			turns.');
		autoTestEnd();
	}

	// Throw an exception, ending the game.
	autoTestEnd() { throw new QuittingException(); }
;

autoTestManager: PreinitObject
	_test = nil

	execute() {
		// Make sure we have a player actor.
		if(gameMain.initialPlayerChar == nil)
			return;

		// Add each test instance to our list.
		forEachInstance(AutoTest, function(o) { _test = o; });

		// Add two bespoke methods to the player character.
		gameMain.initialPlayerChar.setMethod(&executeTurn,
			function() { autoTestManager.executeTurn(); });
		gameMain.initialPlayerChar.setMethod(&autoTestMain,
			function() { autoTestManager.autoTestMain(); });
	}

	// Called by gPlayerChar.executeTurn(), this happens before most of
	// the turn stuff.  
	executeTurn() {
		_test.executeTurn();

		// Call the custom wait command.
		autoTestWait();
	}

	// Invoke our wait command.  This will output a zero-length
	// default report and then call autoTestMain().  We do it
	// this way so that our autoTestTurn() method gets called
	// "inside" the action.  executeTurn() would otherwise be
	// called "before" the action, which makes it slightly more
	// confusing to synchronize turn numbers and so on.
	autoTestWait() { newActorAction(gPlayerChar, AutoTestWait); }

	// Called by AutoTestWaitAction.
	autoTestMain() { _test.autoTestMain(); }
;
