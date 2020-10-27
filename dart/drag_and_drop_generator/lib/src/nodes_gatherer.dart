import 'dart:convert';

import 'package:http/http.dart';

/// Get the nodes.json from the github repo and parse it.
dynamic getNodes(Client client) async {
  final responds = await client.get(
      'https://raw.githubusercontent.com/Seamlezz/Gamelezz-Nodes/main/nodes.json');

  if (responds.statusCode != 200) {
    throw NetworkError('Could not find the github repository nodes.json file');
  }

  return jsonDecode(responds.body);
}

/// Error thrown by the runtime system when an assert statement fails.
class NetworkError extends Error {
  /// Message describing the assertion error.
  final Object message;

  /// Create the error
  NetworkError([this.message]);

  /// Format the error
  @override
  String toString() {
    if (message != null) {
      return 'Network Request failed: ${Error.safeToString(message)}';
    }
    return 'Network Request failed';
  }
}
