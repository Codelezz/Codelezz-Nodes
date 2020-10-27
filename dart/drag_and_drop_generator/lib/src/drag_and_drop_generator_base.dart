import 'dart:convert';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:http/http.dart';

import 'nodes_gatherer.dart';

final _dartfmt = DartFormatter();

/// The parsed version of nodes.json
dynamic nodes;

void main() async {
  nodes = await getNodes(Client());
  startGeneration();
}

/// Start the generation of the class.
void startGeneration() {
  final uuidField = Field(generateUUIDField);
  final n = Class(generateClassBody);
  final staticNodes = Class(generateStaticNodeBody);
  final library = Library((b) => b.body.addAll([uuidField, n, staticNodes]));
  final file =
      _dartfmt.format('${library.accept(DartEmitter())}'.replaceAll('"', '\''));
  print(file);
}

/// Generate uuid static field.
void generateUUIDField(FieldBuilder builder) {
  builder.name = 'uuid';
  builder.modifier = FieldModifier.final$;
  builder.assignment =
      refer('Uuid', 'package:uuid/uuid.dart').newInstance([]).code;
}

/// Generate the class body.
void generateClassBody(ClassBuilder builder) {
  builder.name = 'Nodes';
  builder.fields.add(Field(generateStaticNodes));
  builder.constructors.add(Constructor(generateConstructor));
  builder.methods.add(Method(generateDefaultInitializeMethod));
  builder.methods.add(Method(generateConvertMethod));
}

/// Generate the static nodes list field.
void generateStaticNodes(FieldBuilder builder) {
  builder.name = 'nodes';
  builder.type = refer('List<StaticNode>');
  builder.modifier = FieldModifier.final$;
}

/// Generate the private constructor.
void generateConstructor(ConstructorBuilder builder) {
  builder.body = const Code('this.nodes = _generateStaticNodes();');
}

/// Generate the code that will generate all the static nodes.
void generateDefaultInitializeMethod(MethodBuilder builder) {
  builder.name = '_generateStaticNodes';
  builder.returns = refer('List<StaticNode>');

  dynamic nn = nodes['nodes'];

  var block = Block.of([
    refer('List<StaticNode>').newInstance([]).assignFinal('nodes').statement,
    ...generateNodeTypeCaching(),
    for (var nodeId in nn.keys) generateStaticNodeInitCode(nodeId),
    refer('nodes').returned.statement,
  ]);

  builder.body = block;
}

/// Node have types. We try to cache the enums to make the script run faster.
List<Code> generateNodeTypeCaching() {
  dynamic types = nodes['nodes'].values.map((v) => v['type']).toSet().toList();
  return [
    Code('final typesCache = Map<String, NodeType>();'),
    for (var type in types)
      Code('typesCache.put("$type", NodeType.values'
          '   .firstWhere((e) => e.toString() == "NodeType.$type"));'),
  ];
}

/// Generate the code generation
Code generateStaticNodeInitCode(String nodeId) {
  dynamic nn = nodes['nodes'];
  dynamic node = nn[nodeId];

  var type = 'typesCache["${node['type']}"]';

  return Code('nodes.add(StaticNode('
      'id: "$nodeId", '
      'name: "${node['name']}", '
      'type: $type,'
      '));');
}

/// Generate the method to convert from a node id to a actual nodeable.
void generateConvertMethod(MethodBuilder builder) {
  builder.name = 'convertToNodeable';
  builder.returns = refer('Nodeable');
  builder.requiredParameters.add(Parameter((b) {
    b.name = 'id';
    b.type = refer('String');
  }));

  builder.optionalParameters.addAll(['x', 'y'].map((e) => Parameter((b) {
        b.name = e;
        b.type = refer('double');
        b.defaultTo = Code('0');
        b.named = true;
      })));

  var block = Block.of([
    for (var nodeId in nodes['nodes'].keys) generateIfNodeable(nodeId),
    refer('ArgumentError')
        .newInstance([literalString('Could not find a node with the id: \$id')])
        .thrown
        .statement,
  ]);

  builder.body = block;
}

/// Generate the if statement to match a nodeId with a nodeable instance.
Code generateIfNodeable(String nodeId) {
  dynamic nn = nodes['nodes'];
  dynamic node = nn[nodeId];
  dynamic sels = node['selectors'];

  return Block.of([
    Code('if(id == "$nodeId") {'),
    Code('return Nodeable('),
    Code('id: uuid.v4(),'),
    Code('name: "${node["name"]}",'),
    Code('nodeId: "$nodeId",'),
    Code('type: NodeType.values'
        '   .firstWhere((e) => e.toString() == "NodeType.${node["type"]}"),'),
    Code('runOn: ${jsonEncode(node['run-on'])},'),
    Code('x: x,'),
    Code('y: y,'),
    Code('selectors: ['),
    for (var selectorId in sels.keys)
      ...generateSelectorCreation(selectorId, sels[selectorId]),
    Code('],'),
    Code(');'),
    Code('}'),
  ]);
}

/// Generate the AdvancedSelector creation.
List<Code> generateSelectorCreation(String id, dynamic selector) {
  var type = selector['type'];
  var color = nodes['selector-types'][type]['color'];
  var strategy = 'CacheStrategy.values'
      '   .firstWhere((e) => e.toString() == '
      '"CacheStrategy.${selector["strategy"]}")';

  return [
    Code('AdvancedSelector('),
    Code('id: uuid.v4(),'),
    Code('name: "${selector['name']}",'),
    Code('type: "$type",'),
    Code('color: Color($color),'),
    Code('connectorIn: ${selector['connectorIn'] ?? false},'),
    Code('connectorOut: ${selector['connectorOut'] ?? false},'),
    Code('strategy: $strategy,'),
    Code('selectorId: "$id",'),
    Code('needed: true,'),
    Code('),'),
  ];
}

/// Generate the static node class
void generateStaticNodeBody(ClassBuilder builder) {
  builder.name = 'StaticNode';
  builder.fields.addAll([
    Field((b) {
      b.name = 'id';
      b.type = refer('String');
      b.modifier = FieldModifier.final$;
    }),
    Field((b) {
      b.name = 'name';
      b.type = refer('String');
      b.modifier = FieldModifier.final$;
    }),
    Field((b) {
      b.name = 'type';
      b.type = refer('NodeType', 'providers/gom.dart');
      b.modifier = FieldModifier.final$;
    }),
  ]);
  builder.constructors.add(Constructor((b) {
    b.optionalParameters
        .addAll(['id', 'name', 'type'].map((e) => Parameter((p) {
              p.name = e;
              p.toThis = true;
              p.named = true;
              p.required = false;
            })));
  }));
}
