import 'package:flutter_riverpod/legacy.dart';

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier();
});

class SearchNotifier extends StateNotifier<SearchState> {
  // constructor and super class to inherit the data from extended class
  SearchNotifier() : super(SearchState(search: '', ischange: false));

  void search(String query) {
    state = state.copyWith(search: query);
  }

  void oschange(bool isChange) {
    state = state.copyWith(ischange: isChange);
  }
}

class SearchState {
  final String search;
  final bool ischange;

  SearchState({required this.search, required this.ischange});

  SearchState copyWith({String? search, bool? ischange}) {
    return SearchState(
      search: search ?? this.search,
      ischange: ischange ?? this.ischange,
    );
  }
}
