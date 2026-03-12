// lib/data/models/daily.report.g.dart
part of 'daily.report.dart';

extension GetDailyReportCollection on Isar {
  IsarCollection<DailyReport> get dailyReports => this.collection();
}

const DailyReportSchema = CollectionSchema(
  name: r'DailyReport',
  id: 1122334455667788990,
  properties: {
    r'date': PropertySchema(id: 0, name: r'date', type: IsarType.dateTime),
    r'grandTotal': PropertySchema(id: 1, name: r'grandTotal', type: IsarType.double),
    r'soldProductsSummary': PropertySchema(id: 2, name: r'soldProductsSummary', type: IsarType.stringList),
    r'ticketCount': PropertySchema(id: 3, name: r'ticketCount', type: IsarType.long),
    r'totalCard': PropertySchema(id: 4, name: r'totalCard', type: IsarType.double),
    r'totalCash': PropertySchema(id: 5, name: r'totalCash', type: IsarType.double),
    r'totalExpenses': PropertySchema(id: 6, name: r'totalExpenses', type: IsarType.double),
  },
  estimateSize: _dailyReportEstimateSize,
  serialize: _dailyReportSerialize,
  deserialize: _dailyReportDeserialize,
  deserializeProp: _dailyReportDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dailyReportGetId,
  getLinks: _dailyReportGetLinks,
  attach: _dailyReportAttach,
  version: '3.1.0+1',
);

int _dailyReportEstimateSize(
  DailyReport object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.soldProductsSummary.length * 3;
  for (final s in object.soldProductsSummary) {
    bytesCount += 3 + s.length * 3;
  }
  return bytesCount;
}

void _dailyReportSerialize(
  DailyReport object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeDouble(offsets[1], object.grandTotal);
  writer.writeStringList(offsets[2], object.soldProductsSummary);
  writer.writeLong(offsets[3], object.ticketCount);
  writer.writeDouble(offsets[4], object.totalCard);
  writer.writeDouble(offsets[5], object.totalCash);
  writer.writeDouble(offsets[6], object.totalExpenses);
}

DailyReport _dailyReportDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyReport();
  object.id = id;
  object.date = reader.readDateTime(offsets[0]);
  object.grandTotal = reader.readDouble(offsets[1]);
  object.soldProductsSummary = reader.readStringList(offsets[2]) ?? [];
  object.ticketCount = reader.readLong(offsets[3]);
  object.totalCard = reader.readDouble(offsets[4]);
  object.totalCash = reader.readDouble(offsets[5]);
  object.totalExpenses = reader.readDouble(offsets[6]);
  return object;
}

P _dailyReportDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readStringList(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyReportGetId(DailyReport object) => object.id;
List<IsarLinkBase<dynamic>> _dailyReportGetLinks(DailyReport object) => [];
void _dailyReportAttach(IsarCollection<dynamic> col, Id id, DailyReport object) =>
    object.id = id;