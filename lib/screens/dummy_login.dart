// import 'package:flutter/material.dart';
// // void main() {
// //   runApp(
// //     const MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       home: Dummyloginscreen(),
// //     ),
// //   );
// // }
// class Dummyloginscreen extends StatefulWidget {
//   const Dummyloginscreen({super.key});
//
//
//   @override
//   State<Dummyloginscreen> createState() => _DummyloginscreenState();
// }
//
// class _DummyloginscreenState extends State<Dummyloginscreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _buildTogglebutton(),
//             const SizedBox(height: 20,),
//             _buildphonetext(),
//             const SizedBox(height: 20,),
//             _buildtextfield(),
//
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildTogglebutton() {
//     return
//       Row(
//         children: [
//           Expanded(child: const
//           Text('email',
//               style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold
//               )
//           ),
//           ),
//           const SizedBox(width: 10,),
//           Expanded(child: const
//           Text('phone',
//               style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold
//               )
//           ),
//           )
//         ],
//       );
//   }
//
//
//   Widget _buildphonetext() {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child:(Text('Phone Number',
//         style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold
//         ),
//         textAlign: TextAlign.left,
//       )
//       ),
//     );
//
//   }
//
//   Widget _buildtextfield() {
//     return
//       Container(
//           height: 50,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.grey),
//             color: Colors.white,
//           ),
//           child: Row(
//             children: [
//               const SizedBox(width: 50,
//               child:
//               Padding(padding: EdgeInsets.symmetric(horizontal: 10),
//                 child: Text('+91'),),),
//
//              const VerticalDivider(
//                 color: Colors.grey,
//               ),
//               const SizedBox(width:1),
//               Expanded(child:  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
//                   child:
//               TextField(
//                 decoration: InputDecoration(
//                   border: InputBorder.none,
//                   hintText: 'Enter phone number',
//                 ),
//               )
//               ))
//             ]
//           ),
//       );
//   }
//
// }