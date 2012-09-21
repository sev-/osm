package datacopier;

import org.openstreetmap.josm.Main;
import org.openstreetmap.josm.gui.MainMenu;
import org.openstreetmap.josm.plugins.Plugin;
import org.openstreetmap.josm.plugins.PluginInformation;

public class DataCopierPlugin extends Plugin {

    public DataCopierPlugin(PluginInformation info) {
        super(info);
        MainMenu.add(Main.main.menu.toolsMenu, new CopierAction(Main.map));
    }

}

