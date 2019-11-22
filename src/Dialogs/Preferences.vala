public class Dialogs.Preferences : Gtk.Dialog {
    public string view { get; construct; }
    private Gtk.Stack stack;
    
    public Preferences (string view="home") {
        Object (
            view: view,
            transient_for: Application.instance.main_window,
            deletable: false, 
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: false
        );
    }
    
    construct { 
        width_request = 525;
        height_request = 600;

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (get_home_widget (), "home");
        stack.add_named (get_homepage_widget (), "homepage");
        stack.add_named (get_theme_widget (), "theme");
        stack.add_named (get_labels_widget (), "labels");

        Timeout.add (125, () => {
            stack.visible_child_name = view;
            return false;
        });

        var stack_scrolled = new Gtk.ScrolledWindow (null, null);
        stack_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        stack_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
        stack_scrolled.width_request = 246;
        stack_scrolled.expand = true;
        stack_scrolled.add (stack);

        get_content_area ().pack_start (stack_scrolled, true, true, 0);

        //get_action_area ().visible = false;
        //get_action_area ().no_show_all = true;

        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        response.connect ((response_id) => {
            destroy ();
        });
    }

    private Gtk.Widget get_home_widget () {
        /* General */
        var general_label = new Granite.HeaderLabel (_("General"));
        general_label.margin_start = 6;

        var start_page_item = new PreferenceItem ("go-home", _("Homepage"));
        var badge_item = new PreferenceItem ("planner-badge-count", _("Badge count"));
        var theme_item = new PreferenceItem ("night-light", _("Theme"));
        var general_item = new PreferenceItem ("preferences-system", _("General"), true);

        var general_grid = new Gtk.Grid ();
        general_grid.valign = Gtk.Align.START;
        general_grid.get_style_context ().add_class ("view");
        general_grid.orientation = Gtk.Orientation.VERTICAL;
        general_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        general_grid.add (start_page_item);
        general_grid.add (badge_item);
        general_grid.add (theme_item);
        general_grid.add (general_item);
        general_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        /* Addons */
        var addons_label = new Granite.HeaderLabel (_("Add-ons"));
        addons_label.margin_start = 6;

        var calendar_item = new PreferenceItem ("office-calendar", _("Calendar"));
        var labels_item = new PreferenceItem ("tag", _("Labels"), true);

        var addons_grid = new Gtk.Grid ();
        addons_grid.margin_top = 18;
        addons_grid.valign = Gtk.Align.START;
        addons_grid.get_style_context ().add_class ("view");
        addons_grid.orientation = Gtk.Orientation.VERTICAL;
        addons_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        addons_grid.add (calendar_item);
        addons_grid.add (labels_item);
        addons_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.valign = Gtk.Align.START;
        main_grid.add (general_grid);
        main_grid.add (addons_grid);

        start_page_item.activate_item.connect (() => {
            stack.visible_child_name = "homepage";
        });

        theme_item.activate_item.connect (() => {
            stack.visible_child_name = "theme";
        });

        labels_item.activate_item.connect (() => {
            stack.visible_child_name = "labels";
        });

        return main_grid;
    }

    private Gtk.Widget get_homepage_widget () {
        var top_box = new PreferenceTopBox ("go-home", _("Homepage"));
        
        var description_label = new Gtk.Label (_("When you open up Planner, make sure you see the tasks that are most important. The default homepage is your Inbox view, but you can change it to whatever you'd like:"));
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;
        description_label.margin_bottom = 6;
        description_label.margin_top = 6;
        description_label.margin_start = 12;
        description_label.margin_end = 12;

        var inbox_radio = new Gtk.RadioButton.with_label (null, _("Inbox"));
        inbox_radio.margin_top = 12;
        inbox_radio.get_style_context ().add_class ("preference-item-radio");
        
        var today_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, _("Today"));
        today_radio.get_style_context ().add_class ("preference-item-radio");

        var upcoming_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, _("Upcoming"));
        upcoming_radio.get_style_context ().add_class ("preference-item-radio");

        if (!Application.settings.get_boolean ("homepage-project")) {
            int type = Application.settings.get_int ("homepage-item");
            if (type == 0) {
                inbox_radio.active = true;
            } else if (type == 1) {
                today_radio.active = true;
            } else {
                upcoming_radio.active = true;
            }
        }

        var project_header = new Granite.HeaderLabel (_("Projects"));
        project_header.margin_start = 12;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin_top = 6;
        box.valign = Gtk.Align.START;
        box.hexpand = true;
        box.pack_start (description_label, false, true, 0);
        box.pack_start (inbox_radio, false, true, 0);
        box.pack_start (today_radio, false, true, 0);
        box.pack_start (upcoming_radio, false, true, 0);
        box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        box.pack_start (project_header, false, true, 0);

        foreach (var project in Application.database.get_all_projects ()) {
            if (project.inbox_project == 0) {
                var project_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, project.name);
                project_radio.get_style_context ().add_class ("preference-item-radio");
                box.pack_start (project_radio, false, false, 0);

                project_radio.toggled.connect (() => {
                    Application.settings.set_boolean ("homepage-project", true);
                    Application.settings.set_int64 ("homepage-project-id", project.id);
                });

                if (Application.settings.get_boolean ("homepage-project")) {
                    if (Application.settings.get_int64 ("homepage-project-id") == project.id) {
                        project_radio.active = true;
                    }
                }
            }
        }

        box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        inbox_radio.toggled.connect (() => {
            Application.settings.set_boolean ("homepage-project", false);
            Application.settings.set_int ("homepage-item", 0);
        });

        today_radio.toggled.connect (() => {
            Application.settings.set_boolean ("homepage-project", false);
            Application.settings.set_int ("homepage-item", 1);
        });

        upcoming_radio.toggled.connect (() => {
            Application.settings.set_boolean ("homepage-project", false);
            Application.settings.set_int ("homepage-item", 2);
        });

        return main_box;
    }

    private Gtk.Widget get_theme_widget () {
        var info_box = new PreferenceTopBox ("night-light", _("Theme"));

        var description_label = new Gtk.Label (_("Personalize the look and feel of your Planner by choosing the theme that best suits you."));
        description_label.margin = 6;
        description_label.margin_bottom = 6;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var light_radio = new Gtk.RadioButton.with_label (null, _("Light"));
        light_radio.get_style_context ().add_class ("welcome");
        light_radio.margin_start = 12;
        
        var night_radio = new Gtk.RadioButton.with_label_from_widget (light_radio, _("Night"));
        night_radio.get_style_context ().add_class ("welcome");
        night_radio.margin_start = 12;
        
        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.get_style_context ().add_class ("view");
        main_box.expand = true;

        main_box.pack_start (info_box, false, false, 0);
        main_box.pack_start (description_label, false, false, 0);
        main_box.pack_start (light_radio, false, false, 0);
        main_box.pack_start (night_radio, false, false, 0);

        if (Application.settings.get_boolean ("prefer-dark-style")) {
            night_radio.active = true;
        }

        info_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        light_radio.toggled.connect (() => {
            Application.settings.set_boolean ("prefer-dark-style", false);
        });

        night_radio.toggled.connect (() => {
            Application.settings.set_boolean ("prefer-dark-style", true);
        });

        return main_box;
    }

    private Gtk.Widget get_labels_widget () {
        var top_box = new PreferenceTopBox ("tag", _("Labels"));
        top_box.action_button = "list-add-symbolic";

        var description_label = new Gtk.Label (_("When you open up Planner, make sure you see the tasks that are most important. The default homepage is your Inbox view, but you can change it to whatever you'd like:"));
        description_label.margin = 6;
        description_label.margin_bottom = 12;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_bottom = 1;

        var listbox = new Gtk.ListBox ();
        listbox.valign = Gtk.Align.START;
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.hexpand = true;
        
        box.pack_start (description_label, false, false, 0);
        box.pack_start (separator, false, true, 0);
        box.pack_start (listbox, false, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        add_all_labels (listbox);

        Application.database.label_added.connect ((label) => {
            var row = new Widgets.LabelRow (label);
            
            listbox.add (row);
            listbox.show_all ();

            row.name_entry.grab_focus ();
        });

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        top_box.action_activated.connect (() => {
            var label = new Objects.Label ();
            Application.database.insert_label (label);
        });
        
        return main_box;
    }
    
    private void add_all_labels (Gtk.ListBox listbox)  {           
        foreach (Objects.Label label in Application.database.get_all_labels ()) {
            var row = new Widgets.LabelRow (label);
            listbox.add (row);
        }

        listbox.show_all ();
    }
}

public class PreferenceItemRadio : Gtk.RadioButton {
    public PreferenceItemRadio () {
        get_style_context ().add_class ("view");
    }
}

public class PreferenceItem : Gtk.EventBox {
    private Gtk.Image icon_image;
    private Gtk.Label title_label;

    public string _title;
    public string title {
        get {
            return _title;
        }

        set {
            _title = value;
            title_label.label = _title;
        }
    }

    public string _icon;
    public string icon {
        get {
            return _icon;
        }

        set {
            _icon = value;
            icon_image.gicon = new ThemedIcon (_icon);
        }
    }

    public bool last { get; construct; }

    public signal void activate_item ();

    public PreferenceItem (string icon, string title, bool last=false) {
        Object (
            icon: icon,
            title: title,
            last: last
        );
    }

    construct {
        icon_image = new Gtk.Image ();
        icon_image.pixel_size = 24;

        title_label = new Gtk.Label (null);
        title_label.get_style_context ().add_class ("h3");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.halign = Gtk.Align.START;
        title_label.valign = Gtk.Align.CENTER;

        var button_icon = new Gtk.Image ();
        button_icon.gicon = new ThemedIcon ("pan-end-symbolic");
        button_icon.valign = Gtk.Align.CENTER;
        button_icon.pixel_size = 16;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.hexpand = true;
        box.margin = 6;
        box.margin_end = 12;
        box.pack_start (icon_image, false, false, 0);
        box.pack_start (title_label, false, false, 0);
        box.pack_end (button_icon, false, true, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 32;

        if (last) {
            separator.visible = false;
            separator.no_show_all = true;
        }

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.add (box);
        main_box.add (separator);

        add (main_box);

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS) {
                activate_item ();

                return true;
            }

            return false;
        });
    }
}

public class PreferenceTopBox : Gtk.Box {
    private Gtk.Button default_button;

    public signal void back_activated ();
    public signal void action_activated ();

    public string action_button {
        set {
            var image = new Gtk.Image ();
            image.gicon = new ThemedIcon (value);
            image.pixel_size = 16;

            default_button.image = image;
            default_button.visible = true;
        }
    }

    public PreferenceTopBox (string icon, string title) {
        var back_button = new Gtk.Button.from_icon_name ("arrow-back-symbolic", Gtk.IconSize.MENU);
        back_button.margin = 3;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class ("flat");
        back_button.get_style_context ().add_class ("dim-label");

        var title_button = new Gtk.Label (title);
        title_button.valign = Gtk.Align.CENTER;
        title_button.get_style_context ().add_class ("font-bold");
        title_button.get_style_context ().add_class ("h3");

        default_button = new Gtk.Button ();
        default_button.margin = 3;
        default_button.valign = Gtk.Align.CENTER;
        default_button.get_style_context ().add_class ("flat");
        default_button.get_style_context ().add_class ("dim-label");
        default_button.visible = false;
        default_button.no_show_all = true;
        
        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.pack_start (back_button, false, false, 0);
        header_box.set_center_widget (title_button);
        header_box.pack_end (default_button, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.valign = Gtk.Align.START;
        main_box.pack_start (header_box);

        back_button.clicked.connect (() => {
            back_activated ();
        });

        default_button.clicked.connect (() => {
            action_activated ();
        });

        add (main_box);
    }
}