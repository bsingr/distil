/*jsl:declare distil*/

/** A resource module defined in the module that provides the module.
 */

(function(distil, window, document){

    var moduleIndex= {};
    var fetched= {};
    var root= document.documentElement;
    var head= document.getElementsByTagName('head')[0]||root;
    
    var XHR= window.XMLHttpRequest || (function(){
        var progIdCandidates= ['Msxml2.XMLHTTP.4.0', 'Microsoft.XMLHTTP', 'Msxml2.XMLHTTP'];
        var len= progIdCandidates.length;

        var progId;
        var xhr;
        
        function ConstructXhr()
        {
            return new window.ActiveXObject(ConstructXhr.progId);
        }
        
        while (len--)
        {
            try
            {
                progId= progIdCandidates[len];
                xhr= new window.ActiveXObject(progId);
                //  ActiveXObject constructor throws an exception
                //  if the component isn't available.
                xhr= null;
                ConstructXhr.progId= progId;
                return ConstructXhr;
            }
            catch (e)
            {
                //  Ignore the error
            }
        }
        throw new Error('No XMLHttpRequest implementation found');
    })();
    
    var noop= function(){};
    var fetchAsset= function(url, callback, scope, userData)
    {
        if (url in fetched)
        {
            //  The callback will ALWAYS be called after the calling program
            //  finishes executing.
            window.setTimeout(function(){ callback.call(scope, userData); }, 0);
            return;
        }
        
        var xhr= new XHR();
        xhr.open('GET', url, true);
        
        xhr.onreadystatechange= function()
        {
            if (4!==xhr.readyState)
                return;
            fetched[url]= true;
            var status= xhr.status;
            var succeeded= (status>=200 && status<300) || 304==status;
            
            if (!succeeded)
                throw new Error('Failed to load resource: status=' + status + ' url=' + url);
                
            callback.call(scope, userData);
            xhr.onreadystatechange= noop;
            xhr= null;
        }
        xhr.send(null);
    };

    var SCRIPT_TYPE= 'js';
    var CSS_TYPE= 'css';
    var MODULE_TYPE= 'module';
    
    var injectScript= distil.injectScript= function(url, callback, scope, userData)
    {
        var tag= document.createElement('script');

        var complete= function()
        {
            if (callback)
                callback.call(scope, userData);
            window.__filename__= null;
            tag.onreadystatechage= noop;
            tag= null;
        };
    
        window.__filename__= url;

        tag.onreadystatechange= function()
        {
            var readyState= tag && tag.readyState;
            if ('complete'===readyState || 'loaded'===readyState)
                complete();
        }
        tag.onload= complete;
        tag.type= "text/javascript";
        tag.src= url;
        root.insertBefore(tag, root.firstChild);
    };

    var injectStylesheet= distil.injectStylesheet= function(url, callback, scope, userData)
    {
        var link= document.createElement('link');
        link.type='text/css';
        link.rel='stylesheet';
        link.href='url';
        head.appendChild(link);
        
        if (callback)
            callback.call(scope, url, userData);
    };
    
    var getRunningScriptSource= function()
    {
        var scripts= document.getElementsByTagName("script");
        if (!scripts || !scripts.length)
            throw new Error("Could not find script");

        var l= scripts.length;
        var s, src, lastSlash;

        while (l--)
        {
            if ((src= scripts[l].src))
                return src;
        }
        
        throw new Error("No script tags with src attribute.");
    };
    
    var ResourceInfo= function(type, url, callback, scope, userData)
    {
        if (!type)
        {
            var lastDot= url.lastIndexOf('.');
            type= (-1!==lastDot)?url.substring(lastDot+1):"";
        }
        
        var lastSlash= url.lastIndexOf('/');
        if (-1===lastSlash)
            throw new Error("Couldn't determine path from script src: " + url);
            
        return {
            type: type,
            url: url,
            callback: callback,
            scope: scope,
            userData: userData,
            loadQueue: [],
            fetched: false,
            injected: false,
            callbacksExecuted: false,
            path: url.substring(0, lastSlash+1),
            parent: null
        };
    };

    var rootResource= ResourceInfo(SCRIPT_TYPE, getRunningScriptSource());
    rootResource.fetched= true;
    rootResource.injected= true;
    
    /** currentResource is the resource that is currently executing.
     */
    var currentResource= rootResource;

    var injectResource= function(resource)
    {
        resource.injected= true;
        switch (resource.type)
        {
            case SCRIPT_TYPE:
                injectScript(resource.url, injectionComplete, null, resource);
                break;
            case CSS_TYPE:
                injectStylesheet(resource.url, injectionComplete, null, resource);
                break;
            default:
                throw new Error('Unknown resource type: ' + resource.type);
        }
    };

    /** The execution complete callback for the script.
     */
    var injectionComplete= function(resource)
    {
        while (resource)
        {
            if (resource.loadQueue.length)
            {
                currentResource= resource= resource.loadQueue.shift();
                resource.complete= true;
                if (!resource.fetched)
                    return;
                if (MODULE_TYPE===resource.type)
                    continue;
                injectResource(resource);
                return;
            }

            resource.callbacksExecuted= true;
            if (resource.callback)
                resource.callback.call(resource.scope, resource.userData);
                
            resource= resource.parent;
        }
        
        currentResource= resource ? resource : rootResource;
    };
    
    var fetchComplete= function(resource)
    {
        resource.fetched= true;
        var parent= resource.parent;
        
        if (resource===currentResource)
            injectResource(resource);
    };
    
    var loadResource= function(url, callback, scope, userData, parent)
    {
        var resource= ResourceInfo(null, url, callback, scope, userData);
        parent= parent||currentResource;
        resource.parent= parent;
        parent.loadQueue.push(resource);
        fetchAsset(url, fetchComplete, null, resource);
    };

    var loadFiles= function(module)
    {
        var files= (module.loadQueue||[]).concat(module.required);
        var resource= module.resource;
        var path= module.path;
        
        for (var i=0, len=files.length; i<len; ++i)
            loadResource(path + files[i], null, null, null, resource);
    };
    
    distil.module= function(name, def)
    {
        if (name in moduleIndex)
        {
            var module= moduleIndex[name];
            for (var p in def)
                module[p]= def[p];
            return;
        }

        def.path= currentResource.path + def.folder;
        if ('/'!==def.path.slice(-1))
            def.path+='/';
            
        def.callbacks= [];
        def.loadQueue= [];
        
        moduleIndex[name]= def;
    };

    distil.queue= function(name, fragment)
    {
        var module= moduleIndex[name];
        if (module.resource)
            loadResource(currentResource.path + fragment, null, null, null, module.resource);
        else
            module.loadQueue.push(fragment);
    };
    
    distil.onready= function(callback)
    {
        if (rootResource.callbacksExecuted)
            window.setTimeout(callback, 0);
        else
            rootResource.callback= callback;
    }

    distil.complete= function(name)
    {
        var module= moduleIndex[name];
        if (module.loadQueue.length)
            distil.require(name);
    }        
    
    distil.require= function(name, callback, scope, userData)
    {
        var module= moduleIndex[name];
        if (!module)
            throw new Error('No module with name: ' + name);

        var complete= function()
        {
            if (callback)
                callback.call(scope, userData);
            module.loaded= true;
            module.resource= null;
        };

        if (module.loaded)
        {
            window.setTimeout(complete, 0);
            return;
        }
        
        var resource= module.resource= ResourceInfo(MODULE_TYPE, module.path, complete);
        resource.parent= currentResource;
        resource.fetched= true;
        currentResource.loadQueue.push(resource);

        loadFiles(module);
        
        if (rootResource===currentResource)
            injectionComplete(currentResource);
    }
    
})(window.distil={}, window, document);
