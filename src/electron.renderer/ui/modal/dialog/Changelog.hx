package ui.modal.dialog;

class Changelog extends ui.modal.Dialog {
	var isNewUpdate : Bool;

	public function new(isNewUpdate=false) {
		super("changelog");

		this.isNewUpdate = isNewUpdate;
		canBeClosedManually = !isNewUpdate;
		showVersion();
	}


	override function openAnim() { /* none */ }

	public function showVersion(?version:dn.Version) {
		var all = Const.getChangeLog();
		var changeLog : dn.Changelog.ChangelogEntry = null;
		if( version==null ) {
			// Auto-select last major version
			for(c in all.entries)
				if( c.version.patch==0 ) {
					changeLog = c;
					break;
				}
		}
		else {
			// Pick specific version
			for( c in all.entries )
				if( c.version.isEqual(version) ) {
					changeLog = c;
					break;
				}
		}


		// More compact window for short changelogs
		jContent.removeClass("short");
		if( changeLog.allNoteLines.length<=15 ) {
			var hasImage = false;
			for(l in changeLog.allNoteLines)
				if( l.indexOf("![](")>=0 ) {
					hasImage = true;
					break;
				}

			if( !hasImage )
				jContent.addClass("short");
		}

		// Prepare markdown
		var imgReg = ~/!\[]\((.*?)\)/gim;
		var imgUrl = "![](file:///"+JsTools.getAssetsDir()+"/changelogImg/$1)";
		function _makeMarkdown(lines:Array<String>) {
			var md = lines.join("\n");
			imgUrl = StringTools.replace(imgUrl, " ", "%20");
			md = imgReg.replace(md, imgUrl);
			return md;
		}
		var rawMd = _makeMarkdown(changeLog.allNoteLines);

		// Detect latest patch version for this major update
		var latestPatchedVer = changeLog.version;
		for(c in all.entries)
			if( c.version.hasSameMajorAndMinor(changeLog.version) )
				if( latestPatchedVer==null || latestPatchedVer.patch<c.version.patch )
					latestPatchedVer = c.version;

		// Load page
		loadTemplate("changelog", {
			mainVer: latestPatchedVer.major+"."+latestPatchedVer.minor,
			patchVer: latestPatchedVer.patch>0 ? "."+latestPatchedVer.patch : "",
			app: Const.APP_NAME,
			title: changeLog.title==null ? "" : '&ldquo;&nbsp;'+changeLog.title+'&nbsp;&rdquo;',
		}, false);

		// Optional link to previous noteworthy version
		if( changeLog.version.patch!=0 ) {
			var next = false;
			for(c in all.entries) {
				if( c.version.isEqual(changeLog.version) )
					next = true;
				else if( next && c.version.patch==0 ) {
					var jPrevLink = jContent.find("xml#previousUpdate").clone().children();
					jPrevLink.appendTo("#updateChangelogHtml");
					jPrevLink.find(".version").text( c.version.toString() );
					jPrevLink.click( ev->{
						showVersion(c.version);
						ev.preventDefault();
					 });
					break;
				}
			}
		}

		if( changeLog.version.full.length>=8)
			jContent.find("header .version").addClass("long");

		// Close button
		jContent.find(".close").click( (_)->close() );

		// Versions list
		var jOthers = jContent.find(".others");
		jOthers.click( ev->{
			var ctx = new ui.modal.ContextMenu(jOthers);
			ctx.addTitle(L.t._("LDtk major updates"));
			for( c in Const.getChangeLog().entries ) {
				if( c.version.patch!=0 )
					continue;
				ctx.addAction({
					label: L.t.untranslated( '<strong>${c.version.major+"."+c.version.minor}</strong>' + ( c.title!=null ? " - "+c.title : "" ) ),
					cb: ()->showVersion(c.version),
				});
			}
		} );

		// New update banner
		if( isNewUpdate )
			jOthers.hide();
		else
			jContent.find(".newUpdate").hide();

		// Call Marked parser for main changelog
		js.Syntax.code("parseMd({0}, {1})", rawMd, "updateChangelogHtml");


		// Images animations
		var jImgs = jContent.find("p img");
		jImgs.each( (idx,e)->{
			var jImg = new J(e);
			jImg.unwrap().wrap('<div class="imgWrapper"></div>');
			var jShadow = new J('<div class="shadow"/>').insertAfter(jImg);
		});


		// Hot fixes listing
		if( changeLog.version.patch==0 ) {
			var jHotFixes = jContent.find(".hotfixes");
			var count = 0;
			for(c in all.entries) {
				if( c.version.major!=changeLog.version.major || c.version.minor!=changeLog.version.minor || c.version.patch==0 )
					continue;
				var jHotFix = new J('<div class="hotfix markdownHtml"/>');
				var id = c.version.toString();
				jHotFix.appendTo(jHotFixes);
				jHotFix.attr("id", id);
				jHotFix.click(_->{
					jHotFix.toggleClass("collapsed");
				});

				// Call Marked parser
				var md = _makeMarkdown(c.allNoteLines);
				js.Syntax.code("parseMd({0},{1})", md, id);

				var jVer = new J('<div class="hotfixVersion"/>');
				jVer.append('<span class="icon"></span>');
				jVer.append('Patch ${c.version.toString()}');
				jHotFix.prepend(jVer);
				count++;
			}

			// Highlight latest
			if( changeLog.version.hasSameMajorAndMinor( Const.getAppVersionStr(true) ) ) {
				jHotFixes.find(".hotfix:first").addClass("latest");
				jHotFixes.find(".hotfix:not(:first)").addClass("collapsed");
			}
			else
				jHotFixes.find(".hotfix").addClass("collapsed");

			if( count>0 )
				jContent.find("#updateChangelogHtml").prepend('<h2 class="version">Changes from ${changeLog.version.full}</h2>');
		}

		JsTools.parseComponents(jContent);
	}

}