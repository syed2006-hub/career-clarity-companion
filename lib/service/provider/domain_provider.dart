import 'package:careerclaritycompanion/data/models/doamin_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final domainNamesProvider = FutureProvider<List<DomainModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection("domains").get(); 
  return snapshot.docs.map((doc) => DomainModel.fromSnapshot(doc)).toList();
});
