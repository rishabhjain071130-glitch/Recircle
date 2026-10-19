enum AppTab { home, scan, pickups, impact, history, profile }

extension AppTabIndex on AppTab {
  int get index => AppTab.values.indexOf(this);
}
