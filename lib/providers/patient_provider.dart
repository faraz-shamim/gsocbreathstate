// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breath_state/services/db_service/database.dart';

class PatientProvider extends ChangeNotifier {
  final AppDatabase _db;

  List<Patient> _patients = [];
  Patient? _activePatient;

  static const _activeKey = 'active_patient_id';

  PatientProvider(this._db);

  List<Patient> get patients => _patients;
  Patient? get activePatient => _activePatient;

  Future<void> loadPatients() async {
    _patients = await _db.getAllPatients();

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt(_activeKey);

    if (savedId != null) {
      _activePatient = _patients.firstWhere(
        (p) => p.id == savedId,
        orElse: () => _patients.first,
      );
    } else if (_patients.isNotEmpty) {
      _activePatient = _patients.first;
    }

    notifyListeners();
  }

  Future<void> setActivePatient(Patient patient) async {
    _activePatient = patient;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeKey, patient.id);
    notifyListeners();
  }

  Future<Patient> createPatient(
    String name, {
    int? age,
    String? sex,
    double? heightCm,
    String? notes,
  }) async {
    final patient = await _db.createPatient(
      name: name,
      age: age,
      sex: sex,
      heightCm: heightCm,
      notes: notes,
    );
    await refreshPatients();
    return patient;
  }

  Future<void> updatePatient(
    int id,
    String name, {
    int? age,
    String? sex,
    double? heightCm,
    String? notes,
  }) async {
    await _db.updatePatientInfo(
      id: id,
      name: name,
      age: age,
      sex: sex,
      heightCm: heightCm,
      notes: notes,
    );
    await refreshPatients();
  }

  Future<void> updateResonanceFrequency(int patientId, double frequency) async {
    await _db.updatePatientResonanceFrequency(patientId, frequency);
    await refreshPatients();
  }

  Future<void> deletePatient(int id) async {
    if (_activePatient?.id == id) {
      final others = _patients.where((p) => p.id != id).toList();
      if (others.isNotEmpty) await setActivePatient(others.first);
    }
    await _db.deletePatient(id);
    await refreshPatients();
  }

  Future<void> refreshPatients() async {
    _patients = await _db.getAllPatients();
    if (_activePatient != null) {
      _activePatient = _patients.firstWhere(
        (p) => p.id == _activePatient!.id,
        orElse: () => _patients.first,
      );
    } else if (_patients.isNotEmpty) {
      _activePatient = _patients.first;
    }
    notifyListeners();
  }
}
