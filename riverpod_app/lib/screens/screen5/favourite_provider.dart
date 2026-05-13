import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_app/screens/screen5/favourite_state.dart';
import 'package:riverpod_app/screens/screen5/item.dart';

final favouriteProvider =
    StateNotifierProvider<FavouriteNotifier, FavouriteState>((ref) {
      return FavouriteNotifier();
    });

class FavouriteNotifier extends StateNotifier<FavouriteState> {
  FavouriteNotifier()
    : super(FavouriteState(allItems: [], filteredItems: [], search: ""));

  void addItem() {
    List<Item> item = [
      Item(name: "MacBook", id: 1, favourite: true),
      Item(name: "Google Pixel", id: 2, favourite: false),
      Item(name: "Samsung", id: 3, favourite: false),
      Item(name: "Dell G 15", id: 4, favourite: true),
      Item(name: "Iphone 17 pro max", id: 5, favourite: false),
      Item(name: "Sony a6700", id: 6, favourite: true),
      Item(name: "Dji osmo pocket 3", id: 7, favourite: false),
    ];

    state = state.copyWith(
      allItems: item.toList(),
      filteredItems: item.toList(),
    );
  }
}
