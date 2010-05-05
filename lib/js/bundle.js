
/** A resource bundle defined in the module that provides the bundle.
    
    distil.bundle('MyBundle', {
            root: "/foo/bar/baz/",
            required: ["MyBundle.css", "MyBundle.js"],
            preload: ["welcome.css", "welcome.js"],
            lazy: {
                account: ["account.css", "account.js"],
                settings: ["settings.css", "settings.js"]
            }
        });
    }
 */


(function(distil){

    var bundleIndex= {};
    
    distil.bundle= function(name, def)
    {
        if (name in bundleIndex)
            throw new Error('Redefinition of bundle: ' + name);

        bundleIndex[name]= def;
    };
    
    var bundle= distil.bundle;
    
    bundle.load= function(name, callback)
    {
        
    }
    