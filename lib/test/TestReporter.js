function print(msg)
{
    console.log(msg);
}

var TestReporter= {

    __numberOfFailures: 0,
    __numberOfTests: 0,
    __numberOfPasses: 0,
    __numberOfSkipped: 0,
    
    setup: function()
    {},
    
    complete: function()
    {
        print(this.__numberOfTests + ' tests ' + this.__numberOfPasses + ' passed ' +
              this.__numberOfFailures + ' failed ' + this.__numberOfSkipped + ' skipped');
    },
    
    beginTest: function(test, testName)
    {
        print('begin: ' + test + '#' + testName);
        ++this.__numberOfTests;
    },
    
    endTest: function(test, testName)
    {
        print('end: ' + test + '#' + testName);
    },
    
    failed: function(test, testName, message)
    {
        print('failed: ' + test + "#" + testName + ": " + message);
        ++this.__numberOfFailures;
    },
    
    skipped: function(test, testName, message)
    {
        print('skipped: ' + test + "#" + testName + ': ' + message);
        ++this.__numberOfSkipped;
    },
    
    passed: function(test, testName)
    {
        print('passed: ' + test + '#' + testName);
        ++this.__numberOfPasses;
    },
    
    uncaughtException: function(test, testName, e)
    {
        print('uncaught exception: ' + test + '#' + testName + ': ' +
              e.name + ': ' + e.message);
        ++this.__numberOfFailures;
    },
    
    exceptionInSetup: function(test, testName, e)
    {
        print('uncaught exception in setup: ' + test + '#' + testName + ': ' +
              e.name + ': ' + e.message);
        ++this.__numberOfFailures;
    },

    exceptionInTeardown: function(test, testName, e)
    {
        print('uncaught exception in teardown: ' + test + '#' + testName + ': ' +
              e.name + ': ' + e.message);
        ++this.__numberOfFailures;
    },
    
    timeoutExpired: function(test, testName, timeout)
    {
        print('timeout: ' + test + '#' + testName +
              ': did not complete after ' + timeout + ' milliseconds');
        ++this.__numberOfFailures;
    }
    
};
