// GENERATED MANUAL FILE
// See user.g.dart for pattern

// ignore_for_file: non_constant_identifier_names, unnecessary_this


part of 'business.config.dart';

extension GetBusinessConfigCollection on Isar {
  IsarCollection<BusinessConfig> get businessConfigs => this.collection();
}

const BusinessConfigSchema = CollectionSchema(
  name: r'BusinessConfig',
  id: 2233445566778899001,
  properties: {
    r'businessName': PropertySchema(id: 0, name: r'businessName', type: IsarType.string),
    r'cifNif': PropertySchema(id: 1, name: r'cifNif', type: IsarType.string),
    r'address': PropertySchema(id: 2, name: r'address', type: IsarType.string),
    r'logoPath': PropertySchema(id: 3, name: r'logoPath', type: IsarType.string),
    r'adminPassword': PropertySchema(id: 4, name: r'adminPassword', type: IsarType.string),
    r'phone': PropertySchema(id: 5, name: r'phone', type: IsarType.string),
    r'email': PropertySchema(id: 6, name: r'email', type: IsarType.string),
  },
  estimateSize: _businessConfigEstimateSize,
  serialize: _businessConfigSerialize,
  deserialize: _businessConfigDeserialize,
  deserializeProp: _businessConfigDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _businessConfigGetId,
  getLinks: _businessConfigGetLinks,
  attach: _businessConfigAttach,
  version: '3.1.0+1',
);

int _businessConfigEstimateSize(BusinessConfig object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.businessName.length * 3;
  bytesCount += 3 + object.cifNif.length * 3;
  bytesCount += 3 + object.address.length * 3;
  if (object.logoPath != null) bytesCount += 3 + object.logoPath!.length * 3;
  bytesCount += 3 + object.adminPassword.length * 3;
  if (object.phone != null) bytesCount += 3 + object.phone!.length * 3;
  if (object.email != null) bytesCount += 3 + object.email!.length * 3;
  return bytesCount;
}

void _businessConfigSerialize(BusinessConfig object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeString(offsets[0], object.businessName);
  writer.writeString(offsets[1], object.cifNif);
  writer.writeString(offsets[2], object.address);
  writer.writeString(offsets[3], object.logoPath);
  writer.writeString(offsets[4], object.adminPassword);
  writer.writeString(offsets[5], object.phone);
  writer.writeString(offsets[6], object.email);
}

BusinessConfig _businessConfigDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = BusinessConfig();
  object.id = id;
  object.businessName = reader.readString(offsets[0]);
  object.cifNif = reader.readString(offsets[1]);
  object.address = reader.readString(offsets[2]);
  object.logoPath = reader.readStringOrNull(offsets[3]);
  object.adminPassword = reader.readString(offsets[4]);
  object.phone = reader.readStringOrNull(offsets[5]);
  object.email = reader.readStringOrNull(offsets[6]);
  return object;
}

P _businessConfigDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _businessConfigGetId(BusinessConfig object) => object.id;
List<IsarLinkBase<dynamic>> _businessConfigGetLinks(BusinessConfig object) => [];
void _businessConfigAttach(IsarCollection<dynamic> col, Id id, BusinessConfig object) => object.id = id;
