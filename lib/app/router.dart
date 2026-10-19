enum AppTab { home, scan, pickups, impact, profile }

extension AppTabIndex on AppTab {
  int get index => AppTab.values.indexOf(this);
}
