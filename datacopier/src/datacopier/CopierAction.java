package datacopier;

import java.awt.event.MouseListener;
import java.awt.Cursor;
import java.awt.event.ActionEvent;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.awt.event.MouseEvent;
import java.util.*;

import org.openstreetmap.josm.Main;
import org.openstreetmap.josm.actions.mapmode.MapMode;
import org.openstreetmap.josm.gui.MapFrame;
import org.openstreetmap.josm.data.coor.LatLon;
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

        System.out.println(String.format("Click %f,%f", coor.getX(), coor.getY()));

        DataSet data1 = Main.main.getCurrentDataSet();

        Way w1 = findWay(data1, coor);

        if (w1 != null) {
            data1.setSelected(w1);
          
            Main.map.mapView.repaint();

            System.out.println("Found");

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

            if (w2 != null) {
                System.out.println("Also");
            }
        }

        if (w1 != null && w2 != null) {
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

                        if (w.get("building") == "yes")
                            return w;
            }
        }

        return null;
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

}
