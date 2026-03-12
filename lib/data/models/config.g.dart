// lib/data/models/config.g.dart
part of 'config.dart';

extension GetConfigCollection on Isar {
  IsarCollection<Config> get configs => this.collection();
}

const ConfigSchema = CollectionSchema(
  name: r'Config',
  id: 3344556677889900112,
  properties: {
    r'businessMode': PropertySchema(id: 0, name: r'businessMode', type: IsarType.string),
    r'businessName': PropertySchema(id: 1, name: r'businessName', type: IsarType.string),
    r'printerMacAddress': PropertySchema(id: 2, name: r'printerMacAddress', type: IsarType.string),
  },
  estimateSize: _configEstimateSize,
  serialize: _configSerialize,
  deserialize: _configDeserialize,
  deserializeProp: _configDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _configGetId,
  getLinks: _configGetLinks,
  attach: _configAttach,
  version: '3.1.0+1',
);

int _configEstimateSize(Config object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.businessMode.length * 3;
  bytesCount += 3 + object.businessName.length * 3;
  if (object.printerMacAddress != null) bytesCount += 3 + object.printerMacAddress!.length * 3;
  return bytesCount;
}

void _configSerialize(Config object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeString(offsets[0], object.businessMode);
  writer.writeString(offsets[1], object.businessName);
  writer.writeString(offsets[2], object.printerMacAddress);
}

Config _configDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = Config();
  object.id = id;
  object.businessMode = reader.readString(offsets[0]);
  object.businessName = reader.readString(offsets[1]);
  object.printerMacAddress = reader.readStringOrNull(offsets[2]);
  return object;
}

P _configDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _configGetId(Config object) => object.id;
List<IsarLinkBase<dynamic>> _configGetLinks(Config object) => [];
void _configAttach(IsarCollection<dynamic> col, Id id, Config object) => object.id = id;
