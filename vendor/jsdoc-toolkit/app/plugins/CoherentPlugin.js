JSDOC.PluginManager.registerPlugin("CoherentPlugin", {

    onFunctionCall: function (functionCall)
    {
        if ('Class.create' !== functionCall.name)
            return;

        var superclass = JSDOC.Parser.symbols.getSymbolByName(functionCall.arg1);
            
        var doc = "@lends " + this.lastSymbol.name + ".prototype";

        var desc = this.lastSymbol.comment.getTag('desc');

        if (desc.length)
            desc[0].title = 'class';

        if (superclass && 'CONSTRUCTOR' === superclass.isa)
        {
            this.lastSymbol.comment.tags.push(new JSDOC.DocTag("augments " + superclass.name))
            //  Default to copying the constructor...
            this.lastSymbol.desc= "Constructor inheririted from {@link " + superclass.alias + "}."
            this.lastSymbol.params= superclass.params;
        }

        this.lastSymbol.setTags();
        this.lastSymbol.isa="CONSTRUCTOR";

        functionCall.doc = "/** " + doc + " */";
    },
    
    onSymbol: function (symbol)
    {
        this.lastSymbol = symbol;
    },
    
    onDocCommentSrc: function(comment)
    {
        var src = comment.src.split('\n');

        var indent = "";
        var indentLen = 0;
        var i;
        var l;
        
        for (i = 1; i < src.length; ++i)
        {
            l = src[i];
            indent = l.match(/^\s*/);
                
            if (!indent || !l.trim())
                continue;
            indent = indent[0];
            if (indent.length === l.length)
                continue;
            indentLen = (!indentLen ? indent.length : Math.min(indent.length, indentLen));
        }

        if (!indentLen)
            return;

        indent = new RegExp("^\\s{" + indentLen + "}");

        var lines = src.map(function (l)
            {
                return l.replace(indent, '');
            });
        comment.src = lines.join('\n');
    },
    
    onDocTag: function (tag)
    {
        if ('binding' !== tag.title)
            return;

        tag.desc = tag.nibbleName(tag.desc);
    }
    
});