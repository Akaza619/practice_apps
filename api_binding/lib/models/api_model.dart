// class ApiModel {
//   String? status;
//   Data? data;

//   ApiModel({this.status, this.data});

//   ApiModel.fromJson(Map<String, dynamic> json) {
//     status = json['status'];
//     data = json['data'] != null ? Data.fromJson(json['data']) : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['status'] = status;
//     if (this.data != null) {
//       data['data'] = this.data!.toJson();
//     }
//     return data;
//   }
// }

// class Data {
//   Stats? stats;
//   List<Coins>? coins;
//   Pagination? pagination;

//   Data({this.stats, this.coins, this.pagination});

//   Data.fromJson(Map<String, dynamic> json) {
//     stats = json['stats'] != null ? Stats.fromJson(json['stats']) : null;
//     if (json['coins'] != null) {
//       coins = <Coins>[];
//       json['coins'].forEach((v) {
//         coins!.add(Coins.fromJson(v));
//       });
//     }
//     pagination = json['pagination'] != null
//         ? Pagination.fromJson(json['pagination'])
//         : null;
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     if (stats != null) {
//       data['stats'] = stats!.toJson();
//     }
//     if (coins != null) {
//       data['coins'] = coins!.map((v) => v.toJson()).toList();
//     }
//     if (pagination != null) {
//       data['pagination'] = pagination!.toJson();
//     }
//     return data;
//   }
// }

// class Stats {
//   int? total;
//   int? totalCoins;
//   int? totalMarkets;
//   int? totalExchanges;
//   String? totalMarketCap;
//   String? total24hVolume;

//   Stats({
//     this.total,
//     this.totalCoins,
//     this.totalMarkets,
//     this.totalExchanges,
//     this.totalMarketCap,
//     this.total24hVolume,
//   });

//   Stats.fromJson(Map<String, dynamic> json) {
//     total = json['total'];
//     totalCoins = json['totalCoins'];
//     totalMarkets = json['totalMarkets'];
//     totalExchanges = json['totalExchanges'];
//     totalMarketCap = json['totalMarketCap'];
//     total24hVolume = json['total24hVolume'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['total'] = total;
//     data['totalCoins'] = totalCoins;
//     data['totalMarkets'] = totalMarkets;
//     data['totalExchanges'] = totalExchanges;
//     data['totalMarketCap'] = totalMarketCap;
//     data['total24hVolume'] = total24hVolume;
//     return data;
//   }
// }

// class Coins {
//   String? uuid;
//   String? symbol;
//   String? name;
//   String? color;
//   String? iconUrl;
//   String? marketCap;
//   String? price;
//   int? listedAt;
//   int? tier;
//   String? change;
//   int? rank;
//   List<String>? sparkline;
//   bool? lowVolume;
//   String? coinrankingUrl;
//   String? s24hVolume;
//   String? btcPrice;
//   List<String>? contractAddresses;
//   bool? isWrappedTrustless;
//   Null wrappedTo;

//   Coins({
//     this.uuid,
//     this.symbol,
//     this.name,
//     this.color,
//     this.iconUrl,
//     this.marketCap,
//     this.price,
//     this.listedAt,
//     this.tier,
//     this.change,
//     this.rank,
//     this.sparkline,
//     this.lowVolume,
//     this.coinrankingUrl,
//     this.s24hVolume,
//     this.btcPrice,
//     this.contractAddresses,
//     this.isWrappedTrustless,
//     this.wrappedTo,
//   });

//   Coins.fromJson(Map<String, dynamic> json) {
//     uuid = json['uuid'];
//     symbol = json['symbol'];
//     name = json['name'];
//     color = json['color'];
//     iconUrl = json['iconUrl'];
//     marketCap = json['marketCap'];
//     price = json['price'];
//     listedAt = json['listedAt'];
//     tier = json['tier'];
//     change = json['change'];
//     rank = json['rank'];
//     sparkline = json['sparkline'].cast<String>();
//     lowVolume = json['lowVolume'];
//     coinrankingUrl = json['coinrankingUrl'];
//     s24hVolume = json['24hVolume'];
//     btcPrice = json['btcPrice'];
//     contractAddresses = json['contractAddresses'].cast<String>();
//     isWrappedTrustless = json['isWrappedTrustless'];
//     wrappedTo = json['wrappedTo'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['uuid'] = uuid;
//     data['symbol'] = symbol;
//     data['name'] = name;
//     data['color'] = color;
//     data['iconUrl'] = iconUrl;
//     data['marketCap'] = marketCap;
//     data['price'] = price;
//     data['listedAt'] = listedAt;
//     data['tier'] = tier;
//     data['change'] = change;
//     data['rank'] = rank;
//     data['sparkline'] = sparkline;
//     data['lowVolume'] = lowVolume;
//     data['coinrankingUrl'] = coinrankingUrl;
//     data['24hVolume'] = s24hVolume;
//     data['btcPrice'] = btcPrice;
//     data['contractAddresses'] = contractAddresses;
//     data['isWrappedTrustless'] = isWrappedTrustless;
//     data['wrappedTo'] = wrappedTo;
//     return data;
//   }
// }

// class Pagination {
//   int? limit;
//   bool? hasNextPage;
//   String? nextCursor;

//   Pagination({this.limit, this.hasNextPage, this.nextCursor});

//   Pagination.fromJson(Map<String, dynamic> json) {
//     limit = json['limit'];
//     hasNextPage = json['hasNextPage'];
//     nextCursor = json['nextCursor'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['limit'] = limit;
//     data['hasNextPage'] = hasNextPage;
//     data['nextCursor'] = nextCursor;
//     return data;
//   }
// }

class ApiModel {
  final String? status;
  final List<Coins> coins;

  ApiModel({this.status, required this.coins});

  factory ApiModel.fromJson(Map<String, dynamic> json) {
    return ApiModel(
      status: json['status'],
      coins: json['data']?['coins'] != null
          ? List<Coins>.from(
              json['data']['coins'].map((x) => Coins.fromJson(x)),
            )
          : [],
    );
  }
}

class Coins {
  final String? name;
  final String? symbol;
  final String? price;
  final int? rank;
  final String? iconUrl;

  Coins({this.name, this.symbol, this.price, this.rank, this.iconUrl});

  factory Coins.fromJson(Map<String, dynamic> json) {
    return Coins(
      name: json['name'],
      symbol: json['symbol'],
      price: json['price'],
      rank: json['rank'],
      iconUrl: json['iconUrl'],
    );
  }
}
