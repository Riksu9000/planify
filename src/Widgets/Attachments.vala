/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Widgets.Attachments : Adw.Bin {
    public bool is_board { get; construct; }
    public Objects.Item item { get; set; }

    private Widgets.LoadingButton add_button;
    private Gtk.ListBox listbox;

    public Gee.HashMap <string, Widgets.AttachmentRow> attachments = new Gee.HashMap <string, Widgets.AttachmentRow> ();
    private Gee.HashMap<ulong, GLib.Object> signals_map = new Gee.HashMap<ulong, GLib.Object> ();

    public Attachments (bool is_board = false) {
        Object (
            is_board: is_board
        );
    }

    construct {
        var title = new Gtk.Label (_("Attachments")) {
            css_classes = { "heading", "h4" }
        };

        add_button = new Widgets.LoadingButton.with_icon ("plus-large-symbolic", 16) {
            css_classes = { "flat" },
            hexpand = true,
            halign = END
        };

        var headerbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = is_board ? 9 : 0,
            margin_end = is_board ? 9 : 0
        };
        headerbox.append (title);
        headerbox.append (add_button);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "boxed-list" }
        };
        listbox.set_placeholder (get_placeholder ());

        var listbox_card = new Adw.Bin () {
            child = listbox,
            margin_start = is_board ? 9 : 0,
            margin_end = is_board ? 12 : 0,
            margin_top = is_board ? 6 : 0,
            css_classes = { "transition", "drop-target" }
        };

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_start = is_board ? 3 : 0
        };

        if (!is_board) {
            content.margin_start = 6;
            content.margin_top = 6;
            content.margin_end = 6;
            content.margin_bottom = 6;
        }

        content.append (headerbox);
        content.append (listbox_card);

        child = content;

        add_button.clicked.connect (() => {
            show_file_selector ();
        });

        var dnd_controller = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);
        listbox_card.add_controller (dnd_controller);
        dnd_controller.drop.connect (on_drag_drop);
    }

    private bool on_drag_drop (Value val, double x, double y) {
		var file_list = val as Gdk.FileList;
		if (file_list == null) return false;

		var files = file_list.get_files ();
		if (files.length () == 0) return false;

		File[] files_to_upload = {};
		foreach (var file in files) {
			files_to_upload += file;
		}

		upload_files.begin (files_to_upload, (obj, res) => {
			upload_files.end (res);
		});

        return true;
    }
    
    void show_file_selector () {
		var chooser = new Gtk.FileDialog () {
			// translators: Open file
			title = _("Open"),
			modal = true
		};

        chooser.open_multiple.begin (Planify._instance.main_window, null, (obj, res) => {
			try {
				var files = chooser.open_multiple.end (res);

				File[] files_to_upload = {};
				var amount_of_files = files.get_n_items ();
				for (var i = 0; i < amount_of_files; i++) {
					var file = files.get_item (i) as File;

					if (file != null)
						files_to_upload += file;
				}

				upload_files.begin (files_to_upload, (obj, res) => {
					upload_files.end (res);
				});

			} catch (Error e) {
				// User dismissing the dialog also ends here so don't make it sound like
				// it's an error
				warning (@"Couldn't get the result of FileDialog for AttachmentsPage: $(e.message)");
			}
		});
    }

    private async void upload_files (File[] files) {
        var selected_files_amount = files.length;
		if (selected_files_amount == 0) return;

        Objects.Attachment[] attachments_for_upload = {};
        for (var i = 0; i < selected_files_amount; i++) {
            var file = files[i];
            var attachment = new Objects.Attachment ();

            try {
                var file_info = file.query_info ("standard::size,standard::content-type", 0);
				var file_content_type = file_info.get_content_type ();

                if (file_content_type != null) {
                    file_content_type = file_content_type.down ();

                    attachment.file_size = file_info.get_size ();
                    attachment.file_type = file_content_type;
                    attachment.file_name = file.get_basename ();
                    attachment.file_path = file.get_uri ();

                    attachments_for_upload += attachment;
                }
            } catch (Error e) {
                warning (e.message);
            }
        }

        foreach (Objects.Attachment attachment in attachments_for_upload) {
            attachment.id = Util.get_default ().generate_id ();
            attachment.item_id = item.id;
            item.add_attachment_if_not_exists (attachment);
        }
    }

    public void present_item (Objects.Item _item) {
        item = _item;

        add_attachments ();

        signals_map[item.attachment_added.connect ((attachment) => {
            add_attachment (attachment);
        })] = item;

        signals_map[item.attachment_deleted.connect ((attachment) => {
            if (attachments.has_key (attachment.id)) {
                attachments [attachment.id].hide_destroy ();
                attachments.unset (attachment.id);
            }
        })] = item;
    }

    public void add_attachments () {
        attachments.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }

        foreach (Objects.Attachment attachment in item.attachments) {
            add_attachment (attachment);
        }
    }

    public void add_attachment (Objects.Attachment attachment) {
        if (!attachments.has_key (item.id)) {
            attachments[attachment.id] = new Widgets.AttachmentRow (attachment);
            listbox.append (attachments[attachment.id]);
        }
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("Attach File")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            hexpand = true,
            vexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };
        
        var placeholder_grid = new Gtk.Grid () {
            hexpand = true,
            vexpand = true,
            margin_top = 24,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24
        };

        placeholder_grid.attach (message_label, 0, 0);

        return placeholder_grid;
    }

    public void disconnect_all () {
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }
}

public class Widgets.AttachmentRow : Gtk.ListBoxRow {
    public Objects.Attachment attachment { get; construct; }
    
    private Gtk.Revealer main_revealer;

    public AttachmentRow (Objects.Attachment attachment) {
        Object (
            attachment: attachment
        );
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");

		var name_label = new Gtk.Label (attachment.file_name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

		var close_button = new Widgets.LoadingButton.with_icon ("cross-large-circle-filled-symbolic") {
			valign = CENTER,
			halign = END,
			hexpand = true,
			css_classes = { "flat" },
			tooltip_text = _("Download")
		};

		var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 3
        };

		content_box.append (new Gtk.Image.from_icon_name ("paper-symbolic"));
        content_box.append (name_label);
		content_box.append (close_button);

		main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = content_box
        };

		child = main_revealer;

		Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        var gesture = new Gtk.GestureClick ();
		add_controller (gesture);
		gesture.pressed.connect (() => {
            close_button.is_loading = true;

            try {         
                GLib.AppInfo.launch_default_for_uri (attachment.file_path, null);
                close_button.is_loading = false;
            } catch (Error e) {
                close_button.is_loading = false;
                Services.EventBus.get_default ().send_notification (
                    Util.get_default ().create_toast (e.message)
                );
            }
        });

        var remove_gesture = new Gtk.GestureClick ();
		close_button.add_controller (remove_gesture);
        remove_gesture.pressed.connect (() => {
            remove_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            attachment.delete ();
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}