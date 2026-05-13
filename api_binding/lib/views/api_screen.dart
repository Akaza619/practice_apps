import 'package:api_binding/services/api_bind.dart';
import 'package:flutter/material.dart';

class ApiScreen extends StatefulWidget {
  const ApiScreen({super.key});

  @override
  State<ApiScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ApiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("API Binding")),
      body: FutureBuilder(
        future: ApiBind().fetchData(),
        // builder: (context, snapshot) {
        //   final coins = snapshot.data?.coins ?? [];
        //   return ListView.builder(
        //     itemCount: coins.length,
        //     itemBuilder: (context, index) {
        //       final coin = coins[index];
        //       return ListTile(
        //         leading: Image.network(coin.iconUrl ?? ""),
        //         title: Text(coin.name ?? ""),
        //         subtitle: Text("Price: ${coin.price}"),
        //         trailing: Text("Rank: ${coin.rank}"),
        //       );
        //     },
        //   );
        // },
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.coins == null) {
            return Center(child: Text("No Data"));
          }

          // 🔥 Filter coins with valid image URLs
          final coins = snapshot.data!.coins!
              .where(
                (coin) =>
                    coin.iconUrl != null &&
                    coin.iconUrl!.isNotEmpty &&
                    coin.iconUrl!.startsWith("http"),
              )
              .toList();

          return ListView.builder(
            itemCount: coins.length,
            itemBuilder: (context, index) {
              final coin = coins[index];

              return ListTile(
                leading: Image.network(
                  coin.iconUrl!,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(); // won't show image
                  },
                ),
                title: Text(coin.name ?? ""),
                subtitle: Text("Price: ${coin.price}"),
                trailing: Text("Rank: ${coin.rank}"),
              );
            },
          );
        },
      ),
    );
  }
}
