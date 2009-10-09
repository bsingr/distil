var TestReporter= {

    __numberOfFailures: 0,
    __numberOfTests: 0,
    __numberOfPasses: 0,
    __numberOfSkipped: 0,
    
    __currentTest: '',
    
    setup: function(id)
    {
        this.container= document.getElementById(id);
        this.results= document.createElement('p');
        this.results.className='test-results';
        this.container.appendChild(this.results);
        this.node= document.createElement('ul');
        this.node.className='test-report-items';
        this.container.appendChild(this.node);
    },
    
    statistics: function()
    {
        return {
            numberOfFailures: this.__numberOfFailures,
            numberOfTests: this.__numberOfTests,
            numberOfPasses: this.__numberOfPasses,
            numberOfSkipped: this.__numberOfSkipped
        };
    },
    
    complete: function()
    {
        var text= [this.__numberOfTests, ' tests: ', this.__numberOfPasses,
                   ' passed ', this.__numberOfFailures, ' failed ',
                   this.__numberOfSkipped, ' skipped'].join("");
                   
        var node= document.createTextNode(text);
        this.results.innerHTML="";
        this.results.appendChild(node);
    },
    
    log: function()
    {
        var len= arguments.length;
        var m= [];
        
        for (var i=0; i<len; ++i)
            m.push(String(arguments[i]));
        this.print('  log: ' + this.__currentTest + ': ' + m.join(' '));
    },
    
    print: function(m, status)
    {
        var line= document.createElement('li');
        if (status)
            line.className='test-report-item-' + status;
            
        line.appendChild(document.createTextNode(m));
        var text= line.innerHTML;
        var r= /((?:(?:&lt;)|\s|^)(\w+:\/\/[^\s]*?)(?:(?:&gt;)|\s|$))/g;
        text= text.replace(r, '<a href="$2">$1</a>');
        line.innerHTML= text;
        this.node.appendChild(line);
        
        if ('failure'==status && this.onfailure)
            this.onfailure(m);
    },
    
    beginTest: function(test, testName)
    {
        this.__currentTest= test + '#' + testName;
        ++this.__numberOfTests;
    },
    
    endTest: function(test, testName)
    {
    },
    
    failed: function(test, testName, message)
    {
        this.print('failed: ' + test + "#" + testName + ": " + message, 'failure');
        ++this.__numberOfFailures;
    },

    skipped: function(test, testName, message)
    {
        this.print('skipped: ' + test + "#" + testName + ': ' + message,
                   'skip');
        ++this.__numberOfSkipped;
    },
    
    passed: function(test, testName)
    {
        this.print('passed: ' + test + '#' + testName);
        ++this.__numberOfPasses;
    },
    
    uncaughtException: function(test, testName, e)
    {
        this.print('uncaught exception: ' + test + '#' + testName + ': ' +
                   e.name + ': ' + e.message, 'failure');
        ++this.__numberOfFailures;
    },
    
    exceptionInSetup: function(test, testName, e)
    {
        this.print('uncaught exception in setup: ' + test + '#' + testName + ': ' +
                   e.name + ': ' + e.message, 'failure');
        ++this.__numberOfFailures;
    },

    exceptionInTeardown: function(test, testName, e)
    {
        this.print('uncaught exception in teardown: ' + test + '#' + testName + ': ' +
                   e.name + ': ' + e.message, 'failure');
        ++this.__numberOfFailures;
    },
    
    timeoutExpired: function(test, testName, timeout)
    {
        this.print('timeout: ' + test + '#' + testName +
                   ': did not complete after ' + timeout + ' milliseconds',
                   'failure');
        ++this.__numberOfFailures;
    }
    
};
