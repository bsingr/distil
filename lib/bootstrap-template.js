/*jsl:ignore*/ /**#nocode+*/
(function() {
    var baseUrl= findScriptBaseName();

    function findScriptBaseName()
    {
        var scripts= document.getElementsByTagName("script");
        if (!scripts || !scripts.length)
            throw new Error("Could not find script");

        var l= scripts.length;
        var s;
        
        for (--l; l>=0; --l)
        {
            s= scripts[l];
            if (s.src)
            {
                var src= s.src;
                var lastSlash= src.lastIndexOf('/');
        
                if (-1===lastSlash)
                    throw new Error("Couldn't determine path from src: " + src);
            
                return src.substring(0, lastSlash+1);
            }
        }
        
        throw new Error("No script tags with src attribute.");
    }

    window.__bootstrap_nextScript= function()
    {
        if (!scripts.length)
            window.__filename__= null;
        else
            window.__filename__= scripts.shift();
    }
    
    var scripts= [];
    
    function loadScript(script)
    {
        script= baseUrl + script;
        scripts.push(script);

        if (!window.__filename__)
            window.__bootstrap_nextScript();
        
        document.write( ['<', 'script type="text/javascript"',
                         ' onload="window.__bootstrap_nextScript()"',
                         ' src="', script, '"></script>'].join("") );
    }
    
    @LOAD_SCRIPTS@
    
})();
/**#nocode-*/ /*jsl:end*/
