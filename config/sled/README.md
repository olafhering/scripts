
	gsettings set org.gnome.desktop.interface overlay-scrolling false

	~/.config/gtk-3.0/gtk.css

		scrollbar slider {
			/* Size of the slider */
			min-width: 6mm;
			min-height: 12mm;
			border-radius: 2mm;

			/* Padding around the slider */
			border: 0px solid transparent;
		}

	~/.mozilla/firefox/*/prefs.js

		user_pref("widget.gtk.overlay-scrollbars.enabled", false);
		user_pref("widget.non-native-theme.scrollbar.size.override", 22);
		user_pref("widget.non-native-theme.scrollbar.style", 0);

