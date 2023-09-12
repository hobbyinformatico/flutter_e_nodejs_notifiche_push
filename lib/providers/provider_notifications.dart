import 'package:flutter/material.dart';

class ModelProviderNotifications {
  String? data;
}

class ProviderNotifications extends ChangeNotifier {
  ModelProviderNotifications _modelProviderNotifications = ModelProviderNotifications();

  String? get data => _modelProviderNotifications.data;

  void setData(dynamic newData) {
    _modelProviderNotifications.data = newData;
    notifyListeners(); // Notifica ai widget ascoltatori che lo stato è cambiato
  }

  String getData() {
    return data ?? "nullo";
  }
}
