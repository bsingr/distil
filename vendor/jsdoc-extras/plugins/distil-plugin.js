/*jsl:declare JSDOC*/
JSDOC.PluginManager.registerPlugin("DistilPlugin", {

    onFunctionCall: function (functionCall)
    {
        switch (functionCall.name)
        {
            case 'Class.create':
            case 'Class._create':
                this.onClassCreate(functionCall);
                break;

            case 'Class.extend':
                this.onClassExtend(functionCall);
                break;
                
            case 'Object.extend':
                this.onObjectExtend(functionCall);
                break;
        }
    },
    
    onObjectExtend: function(functionCall)
    {
        var objectSymbol= JSDOC.Parser.symbols.getSymbolByName(functionCall.arg1);
        if (!objectSymbol)
            return;
        var doc= "@lends " + objectSymbol.name;
        functionCall.doc= "/** " + doc + " */";
    },

    onClassExtend: function(functionCall)
    {
        var classSymbol= JSDOC.Parser.symbols.getSymbolByName(functionCall.arg1);
        if (!classSymbol)
            return;
        var doc= "@lends " + classSymbol.name + ".prototype";
        functionCall.doc= "/** " + doc + " */";
    },
    
    onClassCreate: function(functionCall)
    {
        var superclass = JSDOC.Parser.symbols.getSymbolByName(functionCall.arg1);
            
        var doc = "@lends " + this.lastSymbol.name + ".prototype";

        var desc = this.lastSymbol.comment.getTag('desc');

        if (desc.length)
            desc[0].title = 'class';

        if (superclass && 'CONSTRUCTOR' === superclass.isa)
        {
            this.lastSymbol.comment.tags.push(new JSDOC.DocTag("augments " + superclass.name));
            //  Default to copying the constructor...
            this.lastSymbol.desc= "Constructor inheririted from {@link " + superclass.alias + "}.";
            this.lastSymbol.desc= superclass.desc;
            this.lastSymbol.params= superclass.params;
        }

        this.lastSymbol.setTags();
        this.lastSymbol.isa="CONSTRUCTOR";

        functionCall.doc = "/** " + doc + " */";
    },
    
    //  Called during the construction of the Symbol
    onSymbol: function(symbol)
    {
        this.lastSymbol = symbol;
        
        if (!/#constructor$/.test(symbol.name))
            return;

        var classname= symbol.name.slice(0,-12);
        var classSymbol= JSDOC.Parser.symbols.getSymbolByName(classname);
        if (!classSymbol)
            return;

        //  ignore the constructor
        symbol.isIgnored= true;
        
        if (classSymbol.comment.tags)
            classSymbol.comment.tags= (symbol.comment.tags||[]).concat(classSymbol.comment.tags);
        else
            classSymbol.comment.tags= symbol.comment.tags;
        
        classSymbol.params= symbol.params;
        classSymbol.setTags();
    },
    
    onSymbolLink: function(link)
    {
        if ('#'===link.linkText.charAt(0))
            link.linkText= link.linkText.substring(1);
    },
    
    onDocCommentSrc: function(comment)
    {
        var src = comment.src;
        var _this= this;
        // if (/@method\b/.test(src))
        //     print("Method: previous symbol=" + this.lastSymbol.name);
        
        function addScope(match, methodName)
        {
            if (_this.lastSymbol)
                methodName= _this.lastSymbol.alias + "#" + methodName;
            var tag= "@name "+methodName + "\n@function\n@description";
            print("Replacing: \""+match+"\" with \""+tag+"\"");
            return tag;
        }
        src= src.replace(/@method\s+(\S+)/, addScope);

        var indent = "";
        var indentLen = 0;
        var i;
        var l;
        
        src= src.split('\n');
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
    
    onDocTag: function(tag)
    {
        switch (tag.title)
        {
            case 'binding':
                tag.desc= tag.nibbleType(tag.desc);
                tag.desc= tag.nibbleName(tag.desc);
                break;
                
        }
    }
    
});