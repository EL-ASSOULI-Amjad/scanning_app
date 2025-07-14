import 'package:flutter/material.dart';
import 'package:scanning_app/pages/ajout.dart';
import 'package:scanning_app/pages/prendre.dart';
import 'package:scanning_app/pages/profil.dart';
import 'package:scanning_app/pages/stock.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Homepage(),
    routes: {
        '/ajouter': (context) => Ajout(),
        '/prendre': (context) => Prendre(),
        '/stock': (context) => Stock(),
        '/profil': (context) => Profil(),
    },
  ));
}

class Homepage extends StatelessWidget {
  Homepage({super.key});

  final List<String> pagesNames = [
    "Ajouter un produit",
    "Prendre un produit",
    "Consulter le stock",
    "Profil"
  ];

  final List<IconData> icons = [
    Icons.add_box,
    Icons.remove_circle_outline,
    Icons.inventory,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 226, 217, 252),
        child: Center(
          child: SizedBox(
            width: 500,
            height: 500,
            child: GridView.builder(
              itemCount: pagesNames.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
             itemBuilder: (context, index) => GestureDetector(
  onTap: () {
    print('Tapped on index: $index');
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/ajouter');
        break;
      case 1:
        Navigator.pushNamed(context, '/prendre');
        break;
      case 2:
        Navigator.pushNamed(context, '/stock');
        break;
      case 3:
        Navigator.pushNamed(context, '/profil');
        break;
    }
  },
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.deepPurpleAccent,
    ),
    margin: const EdgeInsets.all(10),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icons[index],
          size: 40,
          color: Colors.white,
        ),
        const SizedBox(height: 10),
        Text(
          pagesNames[index],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),
            ),
          ),
        ),
      ),
    );
  }
}
