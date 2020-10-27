import 'dart:convert';

import 'package:drag_and_drop_generator/src/nodes_gatherer.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('Nodes Gatherer - Successful decode nodes', () async {
    final data = {'test': 123};
    final client = MockClient((request) async {
      return Response(jsonEncode(data), 200);
    });

    final nodes = await getNodes(client);

    expect(nodes, data);
  });

  test('Nodes Gatherer - Handle status other than 200', () async {
    final data = {'test': 123};
    var statusCode = 200;
    final client = MockClient((request) async {
      return Response(jsonEncode(data), statusCode++);
    });

    expect(() => getNodes(client), returnsNormally);
    expect(() => getNodes(client), throwsA(TypeMatcher<NetworkError>()));
  });
}
