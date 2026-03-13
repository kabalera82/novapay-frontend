// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily.report.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyReportCollection on Isar {
  IsarCollection<DailyReport> get dailyReports => this.collection();
}

const DailyReportSchema = CollectionSchema(
  name: r'DailyReport',
  id: -3611253067269952573,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'grandTotal': PropertySchema(
      id: 1,
      name: r'grandTotal',
      type: IsarType.double,
    ),
    r'soldProductsSummary': PropertySchema(
      id: 2,
      name: r'soldProductsSummary',
      type: IsarType.stringList,
    ),
    r'ticketCount': PropertySchema(
      id: 3,
      name: r'ticketCount',
      type: IsarType.long,
    ),
    r'totalCard': PropertySchema(
      id: 4,
      name: r'totalCard',
      type: IsarType.double,
    ),
    r'totalCash': PropertySchema(
      id: 5,
      name: r'totalCash',
      type: IsarType.double,
    ),
    r'totalExpenses': PropertySchema(
      id: 6,
      name: r'totalExpenses',
      type: IsarType.double,
    )
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
  {
    for (var i = 0; i < object.soldProductsSummary.length; i++) {
      final value = object.soldProductsSummary[i];
      bytesCount += value.length * 3;
    }
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
  object.date = reader.readDateTime(offsets[0]);
  object.grandTotal = reader.readDouble(offsets[1]);
  object.id = id;
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
      return (reader.readStringList(offset) ?? []) as P;
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

Id _dailyReportGetId(DailyReport object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyReportGetLinks(DailyReport object) {
  return [];
}

void _dailyReportAttach(
    IsarCollection<dynamic> col, Id id, DailyReport object) {
  object.id = id;
}

extension DailyReportQueryWhereSort
    on QueryBuilder<DailyReport, DailyReport, QWhere> {
  QueryBuilder<DailyReport, DailyReport, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyReportQueryWhere
    on QueryBuilder<DailyReport, DailyReport, QWhereClause> {
  QueryBuilder<DailyReport, DailyReport, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyReportQueryFilter
    on QueryBuilder<DailyReport, DailyReport, QFilterCondition> {
  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      grandTotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'grandTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      grandTotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'grandTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      grandTotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'grandTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      grandTotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'grandTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soldProductsSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'soldProductsSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'soldProductsSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'soldProductsSummary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'soldProductsSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'soldProductsSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'soldProductsSummary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'soldProductsSummary',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'soldProductsSummary',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'soldProductsSummary',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'soldProductsSummary',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'soldProductsSummary',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'soldProductsSummary',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'soldProductsSummary',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'soldProductsSummary',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      soldProductsSummaryLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'soldProductsSummary',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      ticketCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      ticketCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ticketCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      ticketCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ticketCount',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      ticketCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ticketCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCardEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCard',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCardGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCard',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCardLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCard',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCardBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCard',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCashEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCash',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCashGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCash',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCashLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCash',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalCashBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalExpensesEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalExpenses',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalExpensesGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalExpenses',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalExpensesLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalExpenses',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterFilterCondition>
      totalExpensesBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalExpenses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension DailyReportQueryObject
    on QueryBuilder<DailyReport, DailyReport, QFilterCondition> {}

extension DailyReportQueryLinks
    on QueryBuilder<DailyReport, DailyReport, QFilterCondition> {}

extension DailyReportQuerySortBy
    on QueryBuilder<DailyReport, DailyReport, QSortBy> {
  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByTicketCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketCount', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByTicketCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketCount', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByTotalCard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCard', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByTotalCardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCard', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByTotalCash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCash', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByTotalCashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCash', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> sortByTotalExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalExpenses', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy>
      sortByTotalExpensesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalExpenses', Sort.desc);
    });
  }
}

extension DailyReportQuerySortThenBy
    on QueryBuilder<DailyReport, DailyReport, QSortThenBy> {
  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByGrandTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grandTotal', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByTicketCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketCount', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByTicketCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketCount', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByTotalCard() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCard', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByTotalCardDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCard', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByTotalCash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCash', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByTotalCashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCash', Sort.desc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy> thenByTotalExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalExpenses', Sort.asc);
    });
  }

  QueryBuilder<DailyReport, DailyReport, QAfterSortBy>
      thenByTotalExpensesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalExpenses', Sort.desc);
    });
  }
}

extension DailyReportQueryWhereDistinct
    on QueryBuilder<DailyReport, DailyReport, QDistinct> {
  QueryBuilder<DailyReport, DailyReport, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<DailyReport, DailyReport, QDistinct> distinctByGrandTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grandTotal');
    });
  }

  QueryBuilder<DailyReport, DailyReport, QDistinct>
      distinctBySoldProductsSummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'soldProductsSummary');
    });
  }

  QueryBuilder<DailyReport, DailyReport, QDistinct> distinctByTicketCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticketCount');
    });
  }

  QueryBuilder<DailyReport, DailyReport, QDistinct> distinctByTotalCard() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCard');
    });
  }

  QueryBuilder<DailyReport, DailyReport, QDistinct> distinctByTotalCash() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCash');
    });
  }

  QueryBuilder<DailyReport, DailyReport, QDistinct> distinctByTotalExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalExpenses');
    });
  }
}

extension DailyReportQueryProperty
    on QueryBuilder<DailyReport, DailyReport, QQueryProperty> {
  QueryBuilder<DailyReport, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyReport, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<DailyReport, double, QQueryOperations> grandTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grandTotal');
    });
  }

  QueryBuilder<DailyReport, List<String>, QQueryOperations>
      soldProductsSummaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'soldProductsSummary');
    });
  }

  QueryBuilder<DailyReport, int, QQueryOperations> ticketCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticketCount');
    });
  }

  QueryBuilder<DailyReport, double, QQueryOperations> totalCardProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCard');
    });
  }

  QueryBuilder<DailyReport, double, QQueryOperations> totalCashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCash');
    });
  }

  QueryBuilder<DailyReport, double, QQueryOperations> totalExpensesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalExpenses');
    });
  }
}
