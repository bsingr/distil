/* Distil bootstrap copyright 2010 Jeff Watkins */

/*jsl:declare distil*/
/*jsl:ignore*/ /**#nocode+*/

(function(window, document) {

    if ('undefined'!==typeof(window.distil))
        return;
        
    var currentScript= null,
        scripts= [],
        callbacks= [];

    var findCurrentScriptPath= function()
    {
        var scripts= document.getElementsByTagName("script");
        if (!scripts || !scripts.length)
            throw new Error("Could not find script");

        var l= scripts.length;
        var s, src, lastSlash;
    
        for (--l; l>=0; --l)
        {
            s= scripts[l];
            if (!s.src)
                continue;
                
            src= s.src;
            lastSlash= src.lastIndexOf('/');

            if (-1===lastSlash)
                throw new Error("Couldn't determine path from src: " + src);
    
            return src.substring(0, lastSlash+1);
        }
    
        throw new Error("No script tags with src attribute.");
    };

    var loadNextScript= function()
    {
        var script= scripts.shift();
        if (!script)
        {
            executeCallbacks();
            return;
        }
    };

    var executeCallbacks= function()
    {
        var root= document.documentElement;
        var tag;

        while (callbacks.length)
        {
            tag= document.createElement('script');
            tag.type= "text/javascript";
            tag.appendChild(document.createTextNode("distil.__runCallback()"));
            root.insertBefore(tag, root.firstChild);
            root.removeChild(tag);
        }
    };

    window.distil= {
    
        debug: false,
        
        __scriptLoaded: function()
        {
            var tag= currentScript;
            var root= document.documentElement;
            root.removeChild(tag);

            window.__filename__= null;
        
            loadNextScript();
        },

        __runCallback: function()
        {
            var fn= callbacks.shift();
            if (!fn)
                return;
            fn();
        },
    
        load: function(script, callback, scope, preventCache)
        {
            var tag= document.createElement('script');
            var root= document.documentElement;

            if (preventCache)
                script= [script, (-1===script.indexOf('?') ? '?' : '&'),
                         '_random=', (new Date()).valueOf()].join('');

            window.__filename__= script;
        
            currentScript= tag;
            tag.onreadystatechange= function()
            {
                var readyState= tag && tag.readyState;
                if ('complete'===readyState || 'loaded'===readyState)
                {
                    callback.call(scope);
                    window.__filename__= null;
                    tag= null;
                }
            }
            tag.onload= function()
            {
                if (tag)
                    callback.call(scope);
                window.__filename__= null;
                tag= null;
            }
            tag.type= "text/javascript";
            tag.src= script;
            root.insertBefore(tag, root.firstChild);
        },
        
        queue: function(script, preventCache)
        {
            if ('/'!==script.charAt(0))
                script= findCurrentScriptPath() + script;
            if (preventCache)
                script= [script, (-1===script.indexOf('?') ? '?' : '&'),
                         '_random=', (new Date()).valueOf()].join('');
                         
            scripts.push(script);
        
            if (!currentScript)
                loadNextScript();
        },

        onready: function(fn)
        {
            callbacks.push(fn);
            if (!scripts.length)
                executeCallbacks();
        }
    };
    
})(this, document);

/**#nocode-*/ /*jsl:end*/
