import 'package:flutter/material.dart';

class MenuItemModel {
  final IconData icon;
  final String title;
  const MenuItemModel(this.icon, this.title);
}

const List<MenuItemModel> profileMenuItems = [
  MenuItemModel(Icons.edit, 'Edit Profile'),
  MenuItemModel(Icons.favorite_border, 'Favorites'),
  MenuItemModel(Icons.settings, 'Settings'),
  //MenuItemModel(Icons.help_outline, 'Help Center'),
  MenuItemModel(Icons.logout, 'Log Out'),
];
