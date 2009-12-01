JSDOC.PluginManager.registerPlugin("InterfacePlugin", {

    //  Called during the construction of the Symbol
    onSymbol: function(symbol)
    {
        if (!symbol.comment)
            return;
        if (symbol.comment.getTag("interface").length)
            symbol.isInterface= true;
        symbol.implementedInterfaces= symbol.comment.getTag("implements");
    },
    
    onDocCommentTags: function(comment)
    {
        var interfaceTag= comment.getTag("interface");
        if (!interfaceTag || !interfaceTag.length)
            return;
        interfaceTag= interfaceTag[0];
        
        if (!comment.getTag("class").length)
            comment.tags.push(new JSDOC.DocTag("class " + interfaceTag.desc));
        if (!comment.getTag("name").length)
            comment.tags.push(new JSDOC.DocTag("name " + interfaceTag.name));
    },
    
    onDocTag: function(tag)
    {
        switch (tag.title)
        {
            case 'interface':
                tag.desc= tag.nibbleName(tag.desc);
                break;
        }
    }
    
});