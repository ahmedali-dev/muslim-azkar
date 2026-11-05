import 'package:flutter/material.dart';
import '../models/zikr.dart';

IconData categoryIcon(AzkarPeriod category) => switch (category) {
  AzkarPeriod.morning => Icons.wb_sunny_rounded,
  AzkarPeriod.evening => Icons.nightlight_round,
  AzkarPeriod.sleep => Icons.bedtime_rounded,
  AzkarPeriod.waking => Icons.alarm_rounded,
  AzkarPeriod.tasbih => Icons.spa_rounded,
  AzkarPeriod.mosque ||
  AzkarPeriod.prayer ||
  AzkarPeriod.afterPrayer ||
  AzkarPeriod.adhan => Icons.mosque_rounded,
  AzkarPeriod.ablution => Icons.water_drop_rounded,
  AzkarPeriod.home => Icons.home_rounded,
  AzkarPeriod.food => Icons.restaurant_rounded,
  AzkarPeriod.hajjUmrah => Icons.travel_explore_rounded,
  AzkarPeriod.namesOfAllah => Icons.auto_awesome_rounded,
  AzkarPeriod.ruqyah => Icons.health_and_safety_rounded,
  AzkarPeriod.deceased => Icons.favorite_outline_rounded,
  _ => Icons.menu_book_rounded,
};
