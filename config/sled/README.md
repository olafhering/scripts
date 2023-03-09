
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


	Settings / Wi-Fi
		Airplane Mode: - -> x

	Settings / Power
		Dim Screen: x
		Screen Blank: 5 -> 2 minutes
			Bug: must be "Never" to not interrupt remote session
		Automatic Suspend: off
		Power Button Behavior: Suspend->Nothing

	Settings / Privacy /Screen Lock
		Blank Screen Delay: 2 -> 1 minute
		Automatic Screen Lock: x -> -

	Settings / Accessibility
		Large Text: - -> x

	Settings / Sharing / Screen Sharing
		Enable: - -> x
		Allow connections to control the screen: - -> x
		Require a password: some password
		Network: eth0


	Passwords and Keys / Passwords / Default keyring / Change password
		set empty password
		
		
	Tweaks / General
		Suspend when laptop lid is closed: x -> -

	Tweaks / Top Bar / Clock
		Weekday: - -> x

	Tweaks / Top Bar / Calendar
		Week Numbers: - -> x

	Extensions
		Applications Menu: - -> x
		Desktop Icons: - -> x
		Places Status Indicator: - -> x
