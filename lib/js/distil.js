/*jsl:declare distil*/

/** A resource bundle defined in the module that provides the bundle.
 */


(function(window, document){

    if (window.distil)
        return;
    var distil= window.distil= {};
    
    var bundleIndex= {};
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

    distil.SCRIPT_TYPE= 'js';
    distil.CSS_TYPE= 'css';
    distil.BUNDLE_TYPE= 'bundle';
    
    distil.injectScript= function(url, callback, scope, userData)
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

    distil.injectStylesheet= function(url, callback, scope, userData)
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

    var rootResource= ResourceInfo(distil.SCRIPT_TYPE, getRunningScriptSource());
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
            case distil.SCRIPT_TYPE:
                distil.injectScript(resource.url, injectionComplete, null, resource);
                break;
            case distil.CSS_TYPE:
                distil.injectStylesheet(resource.url, injectionComplete, null, resource);
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
                if (!resource.fetched)
                    return;
                if (!resource.url)
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
        if (resource===currentResource)
            injectResource(resource);
    };
    
    var loadResource= function(type, url, callback, scope, userData)
    {
        var resource= ResourceInfo(type, url, callback, scope, userData);
        resource.parent= currentResource;
        currentResource.loadQueue.push(resource);
        fetchAsset(url, fetchComplete, null, resource);
    };

    distil.bundle= function(name, def)
    {
        if (name in bundleIndex)
            throw new Error('Redefinition of bundle: ' + name);

        bundleIndex[name]= def;
    };

    distil.queue= function(type, fragment)
    {
        loadResource(type, currentResource.path + fragment);
    };
    
    distil.kick= function()
    {
        if (currentResource===rootResource)
            injectionComplete(currentResource);
    };
    
    distil.onready= function(callback)
    {
        if (rootResource.callbacksExecuted)
            window.setTimeout(callback, 0);
        else
            rootResource.callback= callback;
    }
    
    distil.loadBundle= function(name, callback, scope, userData)
    {
        var bundle= bundleIndex[name];
        if (!bundle)
            throw new Error('No bundle with name: ' + name);
            
        if (bundle.loaded)
        {
            if (callback)
                window.setTimeout(function() { callback.call(scope, userData); }, 0);
            return;
        }
        
        var resource= ResourceInfo(distil.BUNDLE_TYPE, null, callback, scope, userData);
        resource.parent= currentResource;
        resource.fetched= true;
        currentResource.loadQueue.push(resource);
    }
    
})(window, document);