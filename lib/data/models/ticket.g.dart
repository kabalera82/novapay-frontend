// lib/data/models/ticket.g.dart
part of 'ticket.dart';

extension GetTicketCollection on Isar {
  IsarCollection<Ticket> get tickets => this.collection();
}

// ---- Enum maps ----

const _TicketStatusEnumValueMap = {
  r'abierto': 0,
  r'pagado': 1,
  r'cancelado': 2,
};
const _TicketStatusValueEnumMap = {
  0: TicketStatus.abierto,
  1: TicketStatus.pagado,
  2: TicketStatus.cancelado,
};

const _PaymentMethodEnumValueMap = {
  r'efectivo': 0,
  r'tarjeta': 1,
  r'mixto': 2,
};
const _PaymentMethodValueEnumMap = {
  0: PaymentMethod.efectivo,
  1: PaymentMethod.tarjeta,
  2: PaymentMethod.mixto,
};

// ---- TicketLine embedded schema ----

const TicketLineSchema = CollectionSchema(
  name: r'TicketLine',
  id: null,
  properties: {
    r'priceAtMoment': PropertySchema(id: 0, name: r'priceAtMoment', type: IsarType.double),
    r'productName': PropertySchema(id: 1, name: r'productName', type: IsarType.string),
    r'quantity': PropertySchema(id: 2, name: r'quantity', type: IsarType.long),
    r'totalLine': PropertySchema(id: 3, name: r'totalLine', type: IsarType.double),
  },
  estimateSize: _ticketLineEstimateSize,
  serialize: _ticketLineSerialize,
  deserialize: _ticketLineDeserialize,
  deserializeProp: _ticketLineDeserializeProp,
  idName: r'',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _ticketLineGetId,
  getLinks: _ticketLineGetLinks,
  attach: _ticketLineAttach,
  version: '3.1.0+1',
);

int _ticketLineEstimateSize(
  TicketLine object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.productName.length * 3;
  return bytesCount;
}

void _ticketLineSerialize(
  TicketLine object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.priceAtMoment);
  writer.writeString(offsets[1], object.productName);
  writer.writeLong(offsets[2], object.quantity);
  writer.writeDouble(offsets[3], object.totalLine);
}

TicketLine _ticketLineDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TicketLine();
  object.priceAtMoment = reader.readDouble(offsets[0]);
  object.productName = reader.readString(offsets[1]);
  object.quantity = reader.readLong(offsets[2]);
  object.totalLine = reader.readDouble(offsets[3]);
  return object;
}

P _ticketLineDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ticketLineGetId(TicketLine object) => Isar.autoIncrement;
List<IsarLinkBase<dynamic>> _ticketLineGetLinks(TicketLine object) => [];
void _ticketLineAttach(IsarCollection<dynamic> col, Id id, TicketLine object) {}

// ---- Ticket collection schema ----

const TicketSchema = CollectionSchema(
  name: r'Ticket',
  id: 1234567890123456789,
  properties: {
    r'createdAt': PropertySchema(id: 0, name: r'createdAt', type: IsarType.dateTime),
    r'isParked': PropertySchema(id: 1, name: r'isParked', type: IsarType.bool),
    r'lines': PropertySchema(id: 2, name: r'lines', type: IsarType.objectList, target: r'TicketLine'),
    r'paymentMethod': PropertySchema(id: 3, name: r'paymentMethod', type: IsarType.byte, enumMap: _PaymentMethodEnumValueMap),
    r'status': PropertySchema(id: 4, name: r'status', type: IsarType.byte, enumMap: _TicketStatusEnumValueMap),
    r'tableNumber': PropertySchema(id: 5, name: r'tableNumber', type: IsarType.long),
    r'tableOrLabel': PropertySchema(id: 6, name: r'tableOrLabel', type: IsarType.string),
    r'totalAmount': PropertySchema(id: 7, name: r'totalAmount', type: IsarType.double),
    r'uuid': PropertySchema(id: 8, name: r'uuid', type: IsarType.string),
    r'zone': PropertySchema(id: 9, name: r'zone', type: IsarType.string),
  },
  estimateSize: _ticketEstimateSize,
  serialize: _ticketSerialize,
  deserialize: _ticketDeserialize,
  deserializeProp: _ticketDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'TicketLine': TicketLineSchema},
  getId: _ticketGetId,
  getLinks: _ticketGetLinks,
  attach: _ticketAttach,
  version: '3.1.0+1',
);

int _ticketEstimateSize(
  Ticket object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.lines;
    bytesCount += 3 + list.length * 3;
    final offsets2 = allOffsets[TicketLine]!;
    for (var i = 0; i < list.length; i++) {
      bytesCount += _ticketLineEstimateSize(list[i], offsets2, allOffsets);
    }
  }
  if (object.tableOrLabel != null) {
    bytesCount += 3 + object.tableOrLabel!.length * 3;
  }
  bytesCount += 3 + object.uuid.length * 3;
  if (object.zone != null) {
    bytesCount += 3 + object.zone!.length * 3;
  }
  return bytesCount;
}

void _ticketSerialize(
  Ticket object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.isParked);
  writer.writeObjectList<TicketLine>(
    offsets[2],
    allOffsets,
    object.lines,
    _ticketLineSerialize,
  );
  writer.writeByte(offsets[3], object.paymentMethod.index);
  writer.writeByte(offsets[4], object.status.index);
  writer.writeLong(offsets[5], object.tableNumber);
  writer.writeString(offsets[6], object.tableOrLabel);
  writer.writeDouble(offsets[7], object.totalAmount);
  writer.writeString(offsets[8], object.uuid);
  writer.writeString(offsets[9], object.zone);
}

Ticket _ticketDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Ticket();
  object.id = id;
  object.createdAt = reader.readDateTime(offsets[0]);
  object.isParked = reader.readBool(offsets[1]);
  object.lines = reader.readObjectList<TicketLine>(
        offsets[2],
        allOffsets,
        _ticketLineDeserialize,
        TicketLine(),
      ) ??
      [];
  object.paymentMethod =
      _PaymentMethodValueEnumMap[reader.readByteOrNull(offsets[3])] ??
          PaymentMethod.efectivo;
  object.status =
      _TicketStatusValueEnumMap[reader.readByteOrNull(offsets[4])] ??
          TicketStatus.abierto;
  object.tableNumber = reader.readLongOrNull(offsets[5]);
  object.tableOrLabel = reader.readStringOrNull(offsets[6]);
  object.totalAmount = reader.readDouble(offsets[7]);
  object.uuid = reader.readString(offsets[8]);
  object.zone = reader.readStringOrNull(offsets[9]);
  return object;
}

P _ticketDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readObjectList<TicketLine>(
            offset,
            allOffsets,
            _ticketLineDeserialize,
            TicketLine(),
          ) ??
          []) as P;
    case 3:
      return (_PaymentMethodValueEnumMap[reader.readByteOrNull(offset)] ??
          PaymentMethod.efectivo) as P;
    case 4:
      return (_TicketStatusValueEnumMap[reader.readByteOrNull(offset)] ??
          TicketStatus.abierto) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ticketGetId(Ticket object) => object.id;
List<IsarLinkBase<dynamic>> _ticketGetLinks(Ticket object) => [];
void _ticketAttach(IsarCollection<dynamic> col, Id id, Ticket object) =>
    object.id = id;