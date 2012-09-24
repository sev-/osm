// Data Copier for dima_ua imports
//
// (c) 2012 Eugene Sandulenko <sev.mail@gmail.com>
//
// This file is licensed under GPLv2
//
// Usage:
//  't' -- switch to new mode
//  name source layer to r.osm
//  Click -- merge over tags, copies over the way if it doesn't exist in current layer
//  Ctrl -- lets select nearby ways, not just those inside of the click point
//  Shift -- replace geometry and merge tags


package datacopier;

import java.awt.event.MouseListener;
import java.awt.Cursor;
import java.awt.geom.Point2D;
import java.awt.event.ActionEvent;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.awt.event.MouseEvent;
import java.util.*;

import org.openstreetmap.josm.Main;
import org.openstreetmap.josm.actions.mapmode.MapMode;
import org.openstreetmap.josm.gui.MapFrame;
import org.openstreetmap.josm.data.coor.LatLon;
import org.openstreetmap.josm.data.osm.PrimitiveDeepCopy;
import org.openstreetmap.josm.gui.layer.Layer;
import org.openstreetmap.josm.gui.layer.OsmDataLayer;
import org.openstreetmap.josm.data.osm.*;
import org.openstreetmap.josm.tools.Geometry;
import org.openstreetmap.josm.command.*;
import org.openstreetmap.josm.gui.DefaultNameFormatter;
import org.openstreetmap.josm.gui.conflict.tags.CombinePrimitiveResolverDialog;
import org.openstreetmap.josm.gui.conflict.tags.TagConflictResolutionUtil;
import org.openstreetmap.josm.tools.ImageProvider;
import org.openstreetmap.josm.tools.Shortcut;
import static org.openstreetmap.josm.tools.I18n.tr;

public class CopierAction extends MapMode implements MouseListener {

    private boolean ctrl;
    private boolean alt;
    private boolean shift;

    public CopierAction(MapFrame mapFrame) {
        super(tr("Copier"), "copier-sml", tr("Copier."), Shortcut.registerShortcut("tools:coper", tr("Tool: {0}", tr("Copier")), KeyEvent.VK_T, Shortcut.DIRECT), mapFrame, getCursor());
    }

 
    @Override
    public void enterMode() {
        if (!isEnabled()) {
            return;
        }
        super.enterMode();
        Main.map.mapView.setCursor(getCursor());
        Main.map.mapView.addMouseListener(this);
    }

    @Override
    public void exitMode() {
        super.exitMode();
        Main.map.mapView.removeMouseListener(this);
    }

    private static Cursor getCursor() {
        return ImageProvider.getCursor("crosshair", "copier-sml");
    }

 
    @Override
    public void mouseClicked(MouseEvent e) {
        if (!Main.map.mapView.isActiveLayerDrawable()) {
            return;
        }
   
        updateKeyModifiers(e);

        if (e.getButton() != MouseEvent.BUTTON1)
            return;

        if (Main.main.getCurrentDataSet() == null)
            return;

        LatLon coor;
        coor = Main.map.mapView.getLatLon(e.getX(), e.getY());

        DataSet data1 = Main.main.getCurrentDataSet();

        Way w1 = findWay(data1, coor);

        if (w1 != null) {
            data1.setSelected(w1);
          
            Main.map.mapView.repaint();
        }

        DataSet data2 = null;
        for (Layer layer : Main.map.mapView.getAllLayersAsList()) {
            if (layer.getName().equalsIgnoreCase("r.osm")) {
                if (layer instanceof OsmDataLayer) {
                    data2 = ((OsmDataLayer)layer).data;
                }
            }
        }

        Way w2 = null;
        if (data2 != null) {
            w2 = findWay(data2, coor);
        }

        if (w1 != null && w2 != null) { // Merging tags
			if (shift) {
				SequenceCommand replaceGeometryCommands = buildReplaceWayCommand(w1, w2);

				if (replaceGeometryCommands != null) {
					Main.main.undoRedo.add(new SequenceCommand(
											   tr("Replace way {0}", w1.getDisplayName(DefaultNameFormatter.getInstance())),
											   replaceGeometryCommands));
				}
			} else {
				// Copy over tags
				List<Command> commands = new ArrayList<Command>();

				Collection<Command> tagResolutionCommands = getTagConflictResolutionCommands(w2, w1);
				if (tagResolutionCommands != null) {
					// user did not cancel tag merge dialog
					commands.addAll(tagResolutionCommands);

					Main.main.undoRedo.add(new SequenceCommand(
											   tr("Merge tags for way {0}", w1.getDisplayName(DefaultNameFormatter.getInstance())),
											   commands));
				}
            }
        } else if (w1 == null && w2 != null) { // We need to copy over the way
			Collection<OsmPrimitive> ways = new LinkedList<OsmPrimitive> ();

			ways.add(w2);

			pasteData(new PrimitiveDeepCopy(ways));
		}
    }

    public  void pasteData(PrimitiveDeepCopy pasteBuffer) {
        // Make a copy of pasteBuffer and map from old id to copied data id
        List<PrimitiveData> bufferCopy = new ArrayList<PrimitiveData>();
        Map<Long, Long> newNodeIds = new HashMap<Long, Long>();
        Map<Long, Long> newWayIds = new HashMap<Long, Long>();
        Map<Long, Long> newRelationIds = new HashMap<Long, Long>();
        for (PrimitiveData data: pasteBuffer.getAll()) {
            if (data.isIncomplete()) {
                continue;
            }
            PrimitiveData copy = data.makeCopy();
            copy.clearOsmId();
            if (data instanceof NodeData) {
                newNodeIds.put(data.getUniqueId(), copy.getUniqueId());
            } else if (data instanceof WayData) {
                newWayIds.put(data.getUniqueId(), copy.getUniqueId());
            } else if (data instanceof RelationData) {
                newRelationIds.put(data.getUniqueId(), copy.getUniqueId());
            }
            bufferCopy.add(copy);
        }

        // Update references in copied buffer
        for (PrimitiveData data:bufferCopy) {
            if (data instanceof NodeData) {
                NodeData nodeData = (NodeData)data;
				nodeData.setEastNorth(nodeData.getEastNorth());
            } else if (data instanceof WayData) {
                List<Long> newNodes = new ArrayList<Long>();
                for (Long oldNodeId: ((WayData)data).getNodes()) {
                    Long newNodeId = newNodeIds.get(oldNodeId);
                    if (newNodeId != null) {
                        newNodes.add(newNodeId);
                    }
                }
                ((WayData)data).setNodes(newNodes);
            } else if (data instanceof RelationData) {
                List<RelationMemberData> newMembers = new ArrayList<RelationMemberData>();
                for (RelationMemberData member: ((RelationData)data).getMembers()) {
                    OsmPrimitiveType memberType = member.getMemberType();
                    Long newId = null;
                    switch (memberType) {
                    case NODE:
                        newId = newNodeIds.get(member.getMemberId());
                        break;
                    case WAY:
                        newId = newWayIds.get(member.getMemberId());
                        break;
                    case RELATION:
                        newId = newRelationIds.get(member.getMemberId());
                        break;
                    }
                    if (newId != null) {
                        newMembers.add(new RelationMemberData(member.getRole(), memberType, newId));
                    }
                }
                ((RelationData)data).setMembers(newMembers);
            }
        }

        /* Now execute the commands to add the duplicated contents of the paste buffer to the map */

        Main.main.undoRedo.add(new AddPrimitivesCommand(bufferCopy));
        Main.map.mapView.repaint();
    }

    protected static List<Node> getUnimportantNodes(Way way) {
        List<Node> nodePool = new LinkedList<Node>();
        for (Node n : way.getNodes()) {
            List<OsmPrimitive> referrers = n.getReferrers();
            if (!n.isDeleted() && referrers.size() == 1 && referrers.get(0).equals(way)
                    && !hasInterestingKey(n) && !nodePool.contains(n)) {
                nodePool.add(n);
            }
        }
        return nodePool;
    }

    protected static boolean hasImportantNode(Way geometry, Way way) {
        for (Node n : way.getNodes()) {
            // if original and replacement way share a node, it's safe to replace
            if (geometry.containsNode(n)) {
                continue;
            }
            //TODO: if way is connected to other ways, warn or disallow?
            for (OsmPrimitive o : n.getReferrers()) {
                if (o instanceof Relation) {
                    return true;
                }
            }
            if (hasInterestingKey(n)) {
                return true;
            }
        }
        return false;
    }

    protected static boolean hasInterestingKey(OsmPrimitive object) {
        for (String key : object.getKeys().keySet()) {
            if (!OsmPrimitive.isUninterestingKey(key)) {
                return true;
            }
        }
        return false;
    }

    @Override
    protected void updateKeyModifiers(MouseEvent e) {
        ctrl = (e.getModifiers() & ActionEvent.CTRL_MASK) != 0;
        alt = (e.getModifiers() & (ActionEvent.ALT_MASK | InputEvent.ALT_GRAPH_MASK)) != 0;
        shift = (e.getModifiers() & ActionEvent.SHIFT_MASK) != 0;
    }


    @Override
    public void mouseExited(MouseEvent e) {
    }

    @Override
    public void mousePressed(MouseEvent e) {
    }

    @Override
    public void mouseEntered(MouseEvent e) {
    }

    @Override
    public void mouseReleased(MouseEvent e) {
    }

    private Way findWay(DataSet data, LatLon coor) {
        BBox box = new BBox(coor.getX() - 0.00001, coor.getY() - 0.00001,
                coor.getX() + 0.00001, coor.getY() + 0.00001);

        List<Way> searchWays = data.searchWays(box);

        if (searchWays.size() > 0) {
            for (Way w : searchWays) {
                if (ctrl || Geometry.nodeInsidePolygon(new Node(coor), w.getNodes()))

                        if (w.get("building") != null)
                            return w;
            }
        }

        return null;
    }

    public static SequenceCommand buildReplaceWayCommand(Way subjectWay, Way referenceWay) {

        if (hasImportantNode(referenceWay, subjectWay)) {
			return null;
        }

        List<Command> commands = new ArrayList<Command>();
                
        // merge tags
        Collection<Command> tagResolutionCommands = getTagConflictResolutionCommands(referenceWay, subjectWay);
        if (tagResolutionCommands == null) {
            // user canceled tag merge dialog
            return null;
        }
        commands.addAll(tagResolutionCommands);
        
        // Prepare a list of nodes that are not used anywhere except in the way
        List<Node> nodePool = getUnimportantNodes(subjectWay);

        // And the same for geometry, list nodes that can be freely deleted
        List<Node> geometryPool = new LinkedList<Node>();
        for( Node node : referenceWay.getNodes() ) {
            List<OsmPrimitive> referrers = node.getReferrers();
            if( node.isNew() && !node.isDeleted() && referrers.size() == 1
                    && referrers.get(0).equals(referenceWay) && !subjectWay.containsNode(node)
                    && !hasInterestingKey(node) && !geometryPool.contains(node))
                geometryPool.add(node);
        }

        // Find new nodes that are closest to the old ones, remove matching old ones from the pool
        // Assign node moves with least overall distance moved
        Map<Node, Node> nodeAssoc = new HashMap<Node, Node>();
        if (geometryPool.size() > 0 && nodePool.size() > 0) {
			for (Node n : geometryPool) {
				Node nearest = findNearestNode(n, nodePool);
				if (nearest != null) {
					nodeAssoc.put(n, nearest);
					nodePool.remove(nearest);
                }

            }
        }

        // Now that we have replacement list, move all unused new nodes to nodePool (and delete them afterwards)
        for( Node n : geometryPool )
            if( nodeAssoc.containsKey(n) )
                nodePool.add(n);

        // And prepare a list of nodes with all the replacements
        List<Node> geometryNodes = referenceWay.getNodes();
        for( int i = 0; i < geometryNodes.size(); i++ )
            if( nodeAssoc.containsKey(geometryNodes.get(i)) )
                geometryNodes.set(i, nodeAssoc.get(geometryNodes.get(i)));

        // Now do the replacement
        commands.add(new ChangeNodesCommand(subjectWay, geometryNodes));

        // Move old nodes to new positions
        for( Node node : nodeAssoc.keySet() )
            commands.add(new MoveCommand(nodeAssoc.get(node), node.getCoor()));

        // Remove geometry way from selection
        Main.main.getCurrentDataSet().clearSelection(referenceWay);

        // Delete nodes that are not used anymore
        if( !nodePool.isEmpty() )
            commands.add(new DeleteCommand(nodePool));

        // Two items in undo stack: change original way and delete geometry way
        return new SequenceCommand(
                tr("Replace geometry for way {0}", subjectWay.getDisplayName(DefaultNameFormatter.getInstance())),
                commands);
    }

    protected static List<Command> getTagConflictResolutionCommands(OsmPrimitive source, OsmPrimitive target) {
        // determine if the same key in each object has different values
        boolean keysWithMultipleValues;
        Set<OsmPrimitive> set = new HashSet<OsmPrimitive>();
        set.add(source);
        set.add(target);
        TagCollection tagCol = TagCollection.unionOfAllPrimitives(set);
        Set<String> keys = tagCol.getKeysWithMultipleValues();
        keysWithMultipleValues = !keys.isEmpty();
            
        Collection<OsmPrimitive> primitives = Arrays.asList(source, target);
        
        Set<RelationToChildReference> relationToNodeReferences = RelationToChildReference.getRelationToChildReferences(primitives);

        // build the tag collection
        TagCollection tags = TagCollection.unionOfAllPrimitives(primitives);
        TagConflictResolutionUtil.combineTigerTags(tags);
        TagConflictResolutionUtil.normalizeTagCollectionBeforeEditing(tags, primitives);
        TagCollection tagsToEdit = new TagCollection(tags);
        TagConflictResolutionUtil.completeTagCollectionForEditing(tagsToEdit);

        // launch a conflict resolution dialog, if necessary
        CombinePrimitiveResolverDialog dialog = CombinePrimitiveResolverDialog.getInstance();
        dialog.getTagConflictResolverModel().populate(tagsToEdit, tags.getKeysWithMultipleValues());
        dialog.getRelationMemberConflictResolverModel().populate(relationToNodeReferences);
        dialog.setTargetPrimitive(target);
        dialog.prepareDefaultDecisions();

        // conflict resolution is necessary if there are conflicts in the merged tags
        // or if both objects have relation memberships
        if (keysWithMultipleValues || 
                (!RelationToChildReference.getRelationToChildReferences(source).isEmpty() &&
                 !RelationToChildReference.getRelationToChildReferences(target).isEmpty())) {
            dialog.setVisible(true);
            if (dialog.isCanceled()) {
                return null;
            }
        }
        return dialog.buildResolutionCommands();
    }

    protected static Node findNearestNode( Node node, Collection<Node> nodes ) {
        if( nodes.contains(node) )
            return node;
        
        Node nearest = null;
        // TODO: use meters instead of degrees, but do it fast
        double distance = Double.parseDouble(Main.pref.get("utilsplugin2.replace-geometry.max-distance", "1"));
        Point2D coor = node.getCoor();

        for( Node n : nodes ) {
            double d = n.getCoor().distance(coor);
            if( d < distance ) {
                distance = d;
                nearest = n;
            }
        }
        return nearest;
    }
}
