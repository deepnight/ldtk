package tool.lt;

class EntityTool extends tool.LayerTool<Int> {
	public var curEntityDef(get,never) : Null<data.def.EntityDef>;
	public static var PREV_CHAINABLE_ENT: Null<{ ei:data.inst.EntityInstance, time:Float }>;

	public function new() {
		super();

		if( curEntityDef==null && project.defs.entities.length>0 )
			selectValue( project.defs.entities[0].uid );
	}

	public static inline function clearPrevAutoRefEntity() {
		PREV_CHAINABLE_ENT = null;
	}

	override function onBeforeToolActivation() {
		super.onBeforeToolActivation();

		if( curEntityDef==null )
			selectValue( getDefaultValue() );
	}

	inline function get_curEntityDef() return project.defs.getEntityDef( getSelectedValue() );

	override function selectValue(v:Int) {
		super.selectValue(v);
	}

	override function canEdit():Bool {
		return super.canEdit() && getSelectedValue()>=0 && settings.v.showDetails;
	}

	override function getDefaultValue():Int{
		if( project.defs.entities.length>0 )
			return project.defs.entities[0].uid;
		else
			return -1;
	}

	function getPlacementX(m:Coords) {
		return snapToGrid()
			? M.round( ( m.cx + curEntityDef.pivotX ) * curLayerInstance.def.gridSize )
			: m.levelX;
	}

	function getPlacementY(m:Coords) {
		return snapToGrid()
			? M.round( ( m.cy + curEntityDef.pivotY ) * curLayerInstance.def.gridSize)
			: m.levelY;
	}

	override function customCursor(ev:hxd.Event, m:Coords) {
		super.customCursor(ev,m);

		if( curEntityDef==null ) {
			editor.cursor.set(Forbidden);
			ev.cancel = true;
		}
		else if( !settings.v.showDetails ) {
			editor.cursor.set(Forbidden);
			ev.cancel = true;
		}
		else if( isRunning() && curMode==Remove ) {
			editor.cursor.set( Eraser(m.levelX,m.levelY) );
			ev.cancel = true;
		}
		else if( curLevel.inBounds(m.levelX, m.levelY) ) {
			var ge = editor.getGenericLevelElementAt(m, true);
			switch ge {
				case Entity(li, ei):
					editor.cursor.set( Entity(curLayerInstance, ei.def, ei, ei.x, ei.y) );
					editor.cursor.overrideNativeCursor("grab");

				case PointField(li, ei, fi, arrayIdx):
					editor.cursor.set(Move);
					// var pt = fi.getPointGrid(arrayIdx);
					// editor.cursor.set( GridCell(curLayerInstance, pt.cx, pt.cy, ei.getSmartColor(false)) );
					// editor.cursor.overrideNativeCursor("grab");

				case _:
					editor.cursor.set( Entity(curLayerInstance, curEntityDef, getPlacementX(m), getPlacementY(m)) );
			}
			ev.cancel = true;
		}
	}


	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);

		if(ev.button==1)
			clearPrevAutoRefEntity();

		var ge = editor.getGenericLevelElementAt(m);
		switch ge {
			case Entity(_) if( ev.button==0 ):
				editor.selectionTool.startUsing(ev,m);
				stopUsing(m);
				return;

			case PointField(_) if( ev.button==0 ):
				editor.selectionTool.startUsing(ev,m);
				stopUsing(m);
				return;

			case _:
		}

		if( ev.button!=2 )
			editor.selectionTool.clear();

		switch curMode {
			case null:
			case Add:
				if( curLevel.inBounds(m.levelX, m.levelY) ) {
					// Create entity
					var ei : data.inst.EntityInstance = null; // will stay null if some limit prevents adding more
					if( curEntityDef.maxCount<=0 )
						ei = curLayerInstance.createEntityInstance(curEntityDef);
					else {
						// Apply count limit
						var all = [];
						switch curEntityDef.limitScope {
							case PerLayer:
								for(ei in curLayerInstance.entityInstances)
									if( ei.defUid==curEntityDef.uid )
										all.push({ ei:ei, li:curLayerInstance });

							case PerLevel:
								for(li in curLevel.layerInstances)
								for(ei in li.entityInstances)
									if( ei.defUid==curEntityDef.uid )
										all.push({ ei:ei, li:li });

							case PerWorld:
								for(l in project.levels)
								for(li in l.layerInstances)
								for(ei in li.entityInstances)
									if( ei.defUid==curEntityDef.uid )
										all.push({ ei:ei, li:li });
						}
						switch curEntityDef.limitBehavior {
							case DiscardOldOnes:
								while( all.length>=curEntityDef.maxCount ) {
									var e = all.shift();
									e.li.removeEntityInstance( e.ei );
								}
								ei = curLayerInstance.createEntityInstance(curEntityDef);

							case PreventAdding:
								if( all.length<curEntityDef.maxCount )
									ei = curLayerInstance.createEntityInstance(curEntityDef);
								else
									N.error(L.t._("You cannot have more than ::n:: ::name::.", { n:curEntityDef.maxCount, name:curEntityDef.identifier }));

							case MoveLastOne:
								if( all.length>=curEntityDef.maxCount && all.length>0 ) {
									var e = all.shift();
									e.li.removeEntityInstance(e.ei);
									curLayerInstance.entityInstances.push(e.ei);
									editor.levelRender.invalidateLayer(curLayerInstance);
									ei = e.ei;
								}
								else
									ei = curLayerInstance.createEntityInstance(curEntityDef);
						}
					}

					// Done
					if( ei!=null ) {
						// Try to auto chain previous entity to the new one
						ei.tidy(project, curLayerInstance); // create field instances
						var allowChain = true;
						if( PREV_CHAINABLE_ENT!=null && !PREV_CHAINABLE_ENT.ei._li.containsEntity(PREV_CHAINABLE_ENT.ei) )
							PREV_CHAINABLE_ENT = null;

						if( PREV_CHAINABLE_ENT!=null && M.fabs(haxe.Timer.stamp()-PREV_CHAINABLE_ENT.time)<=30 ) {
							// Check if previously added entity has a field with "autoChainRef" enabled
							for(prevFi in PREV_CHAINABLE_ENT.ei.fieldInstances) {
								if( prevFi.def.type!=F_EntityRef || !prevFi.def.autoChainRef )
									continue;

								// Create link to previous
								if( prevFi.def.acceptsEntityRefTo(PREV_CHAINABLE_ENT.ei, ei) ) {
									if( prevFi.def.isArray )
										prevFi.addArrayValue();
									prevFi.setEntityRefTo(prevFi.getArrayLength()-1, PREV_CHAINABLE_ENT.ei, ei);
									allowChain = prevFi.def.isArray || !prevFi.def.symmetricalRef;
								}
							}
						}
						if( allowChain )
							PREV_CHAINABLE_ENT = { ei:ei, time:haxe.Timer.stamp() }
						else
							PREV_CHAINABLE_ENT = null;

						// Finalize entity
						ei.x = getPlacementX(m);
						ei.y = getPlacementY(m);
						editor.selectionTool.select([ Entity(curLayerInstance, ei) ]);
						onEditAnything();
						stopUsing(m);
						if( ei.def.isResizable() && editor.resizeTool!=null )
							editor.resizeTool.startUsing(ev, m);
						else
							editor.selectionTool.startUsing(ev, m);
						editor.ge.emit( EntityInstanceAdded(ei) );
					}
				}

			case Remove:
				removeAnyEntityOrPointAt(m);
		}
	}


	function removeAnyEntityOrPointAt(m:Coords) {
		var ge = editor.getGenericLevelElementAt(m, true);
		switch ge {
			case Entity(curLayerInstance, instance):
				curLayerInstance.removeEntityInstance(instance);
				editor.ge.emit( EntityInstanceRemoved(instance) );
				editor.levelRender.bleepEntity(curLayerInstance, instance);
				return true;

			case PointField(li, ei, fi, arrayIdx):
				var pt = fi.getPointGrid(arrayIdx);
				if( pt!=null && pt.cx==m.cx && pt.cy==m.cy ) {
					if( fi.def.isArray )
						fi.removeArrayValue(arrayIdx);
					else
						fi.parseValue(arrayIdx, null);
					editor.ge.emit( EntityFieldInstanceChanged(ei,fi) );
					editor.selectionTool.select([ GenericLevelElement.Entity(li,ei) ]);
					editor.levelRender.bleepPoint(
						(pt.cx+0.5) * li.def.gridSize,
						(pt.cy+0.5) * li.def.gridSize,
						ei.getSmartColor(true)
					);
					return true;
				}
				else
					return false;

			case _:
		}

		return false;
	}


	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev,m);

		if( !ev.cancel ) {
			var ge = editor.getGenericLevelElementAt(m);
			switch ge {
				case Entity(_), PointField(_): editor.selectionTool.onMouseMove(ev,m);
				case _:
			}
		}
	}

	override function useAt(m:Coords, isOnStop) {
		super.useAt(m,isOnStop);

		switch curMode {
			case null:
			case Add:

			case Remove:
				if( removeAnyEntityOrPointAt(m) )
					return true;
		}

		return false;
	}

	override function useOnRectangle(m:Coords, left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(m, left, right, top, bottom);
		return false;
	}


	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.EntityPalette(this);
	}
}