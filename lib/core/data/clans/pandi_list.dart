// pandi_list.dart
// PANDI moiety tharavadu list - single source of truth is Supabase `clans` table.

import '../../models/models.dart';

/// Empty baseline ID set. Dynamic lookups query Supabase clans table via TharavaduService.
const Set<int> pandiClanIds = {};

/// Dynamic list populated strictly from Supabase `clans` table via TharavaduService.
final List<Clan> pandiClans = [];
