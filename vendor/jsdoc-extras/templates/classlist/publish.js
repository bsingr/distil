/** Called automatically by JsDoc Toolkit. */
function publish(symbolSet) {
	publish.conf = {  // trailing slash expected for dirs
		ext:         ".html",
		outDir:      JSDOC.opt.d || SYS.pwd+"../out/jsdoc/",
		templatesDir: JSDOC.opt.t || SYS.pwd+"../templates/jsdoc/",
		symbolsDir:  "symbols/",
		srcDir:      "symbols/src/"
	};
	
	// is source output is suppressed, just display the links to the source file
	if (JSDOC.opt.s && defined(Link) && Link.prototype._makeSrcLink) {
		Link.prototype._makeSrcLink = function(srcFilePath) {
			return "&lt;"+srcFilePath+"&gt;";
		}
	}
	
	// used to allow Link to check the details of things being linked to
	Link.symbolSet = symbolSet;

	// create the required templates
	try {
		var classesTemplate = new JSDOC.JsPlate(publish.conf.templatesDir+"all-classes.tmpl");
	}
	catch(e) {
		print("Couldn't create the required templates: "+e);
		quit();
	}
	
	// some ustility filters
	function hasNoParent($) {return (!$.memberOf);}
	function isaFile($) {return ($.is("FILE"));}
	function isaClass($) {return ($.is("CONSTRUCTOR") || $.isNamespace) && '_global_'!=$.alias;}
	
	// get an array version of the symbolset, useful for filtering
	var symbols = symbolSet.toArray();
	
 	// get a list of all the classes in the symbolset
 	var classes = symbols.filter(isaClass);
	var classesIndex = classesTemplate.process(classes);
	
	IO.saveFile(publish.conf.outDir, 'classes.js', classesIndex);
}
