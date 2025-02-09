// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:jobee_server/main.dart';
// import 'package:lottie/lottie.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();

//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (context) => const HomePage()));
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             const Column(
//               children: [
//                 Hero(
//                   tag: 'as',
//                   child: Text(
//                     'JOBEE',
//                     style: TextStyle(fontSize: 50,
//                     fontWeight: FontWeight.bold
//                     ),
//                   ),
//                 ),
//                 Text(
//                   'Server Side',
//                   style: TextStyle(fontSize: 20),
//                 ),
//               ],
//             ),
//             Column(
//               children: [
//                 SizedBox(
//                   height: 100,
//                   child: Lottie.asset(
//                     'lib/assets/anima1.json',
//                   ),
//                 ),
//                 const Text('Loading')
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
