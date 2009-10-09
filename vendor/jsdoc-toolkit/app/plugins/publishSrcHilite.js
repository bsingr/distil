JSDOC.PluginManager.registerPlugin(
	"JSDOC.publishSrcHilite",
	{
		onPublishSrc: function(src) {
			if (src.path in JsHilite.cache) {
				return; // already generated src code
			}
			else JsHilite.cache[src.path] = true;
		
			try {
				var sourceCode = IO.readFile(src.path);
			}
			catch(e) {
				print(e.message);
				quit();
			}

			var hiliter = new JsHilite(sourceCode, src.charset);
			src.hilited = hiliter.hilite();
		}
	}
);

function JsHilite(src, charset) {

	var tr = new JSDOC.TokenReader();
	
	tr.keepComments = true;
	tr.keepDocs = true;
	tr.keepWhite = true;
	
	this.tokens = tr.tokenize(new JSDOC.TextStream(src));
	
	// TODO is redefining toString() the best way?
	JSDOC.Token.prototype.toString = function() { 
		return "<span class=\""+this.type+"\">"+this.data.replace(/</g, "&lt;")+"</span>";
	}
	
	if (!charset) charset = "utf-8";
	
	this.header = '<html><head><meta http-equiv="content-type" content="text/html; charset='+charset+'"> '+
	"<style>\n\
	BODY { color: #333; }\n\
	PRE { font: 14px consolas, \"panic sans\", monaco, \"courier new\", monospace; line-height: 18px;}\n\
	.KEYW {color: #933;}\n\
	.COMM {color: #999; font-style: italic;}\n\
	.NUMB {color: #393;}\n\
	.STRN {color: #393;}\n\
	.REGX {color: #339;}\n\
	.line {border-right: 1px solid #999; color: #666; font-style: normal; display: inline-block; padding-right: 4px;}\n\
	</style></head><body><pre>";
	this.footer = "</pre></body></html>";
	this.showLinenumbers = true;
}

JsHilite.cache = {};

JsHilite.prototype.hilite = function() {
	var hilited = this.tokens.join("");
	var line = 1;
	if (this.showLinenumbers) hilited = hilited.replace(/(^|\n)/g, function(m){return m+"<span class='line'>"+((line<10)? " ":"")+((line<100)? " ":"")+(line++)+"</span> "});
	
	return this.header+hilited+this.footer;
}