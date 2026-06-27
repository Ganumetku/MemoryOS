// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_up_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFollowUpModelCollection on Isar {
  IsarCollection<FollowUpModel> get followUpModels => this.collection();
}

const FollowUpModelSchema = CollectionSchema(
  name: r'FollowUpModel',
  id: 7387045246447373419,
  properties: {
    r'memoryId': PropertySchema(
      id: 0,
      name: r'memoryId',
      type: IsarType.long,
    ),
    r'question': PropertySchema(
      id: 1,
      name: r'question',
      type: IsarType.string,
    ),
    r'scheduledAt': PropertySchema(
      id: 2,
      name: r'scheduledAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 3,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _followUpModelEstimateSize,
  serialize: _followUpModelSerialize,
  deserialize: _followUpModelDeserialize,
  deserializeProp: _followUpModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'memoryId': IndexSchema(
      id: -5774343511955247558,
      name: r'memoryId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'memoryId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _followUpModelGetId,
  getLinks: _followUpModelGetLinks,
  attach: _followUpModelAttach,
  version: '3.1.0+1',
);

int _followUpModelEstimateSize(
  FollowUpModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.question.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _followUpModelSerialize(
  FollowUpModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.memoryId);
  writer.writeString(offsets[1], object.question);
  writer.writeDateTime(offsets[2], object.scheduledAt);
  writer.writeString(offsets[3], object.status);
}

FollowUpModel _followUpModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FollowUpModel();
  object.id = id;
  object.memoryId = reader.readLong(offsets[0]);
  object.question = reader.readString(offsets[1]);
  object.scheduledAt = reader.readDateTime(offsets[2]);
  object.status = reader.readString(offsets[3]);
  return object;
}

P _followUpModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _followUpModelGetId(FollowUpModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _followUpModelGetLinks(FollowUpModel object) {
  return [];
}

void _followUpModelAttach(
    IsarCollection<dynamic> col, Id id, FollowUpModel object) {
  object.id = id;
}

extension FollowUpModelByIndex on IsarCollection<FollowUpModel> {
  Future<FollowUpModel?> getByMemoryId(int memoryId) {
    return getByIndex(r'memoryId', [memoryId]);
  }

  FollowUpModel? getByMemoryIdSync(int memoryId) {
    return getByIndexSync(r'memoryId', [memoryId]);
  }

  Future<bool> deleteByMemoryId(int memoryId) {
    return deleteByIndex(r'memoryId', [memoryId]);
  }

  bool deleteByMemoryIdSync(int memoryId) {
    return deleteByIndexSync(r'memoryId', [memoryId]);
  }

  Future<List<FollowUpModel?>> getAllByMemoryId(List<int> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'memoryId', values);
  }

  List<FollowUpModel?> getAllByMemoryIdSync(List<int> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'memoryId', values);
  }

  Future<int> deleteAllByMemoryId(List<int> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'memoryId', values);
  }

  int deleteAllByMemoryIdSync(List<int> memoryIdValues) {
    final values = memoryIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'memoryId', values);
  }

  Future<Id> putByMemoryId(FollowUpModel object) {
    return putByIndex(r'memoryId', object);
  }

  Id putByMemoryIdSync(FollowUpModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'memoryId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMemoryId(List<FollowUpModel> objects) {
    return putAllByIndex(r'memoryId', objects);
  }

  List<Id> putAllByMemoryIdSync(List<FollowUpModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'memoryId', objects, saveLinks: saveLinks);
  }
}

extension FollowUpModelQueryWhereSort
    on QueryBuilder<FollowUpModel, FollowUpModel, QWhere> {
  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhere> anyMemoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'memoryId'),
      );
    });
  }
}

extension FollowUpModelQueryWhere
    on QueryBuilder<FollowUpModel, FollowUpModel, QWhereClause> {
  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause> memoryIdEqualTo(
      int memoryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'memoryId',
        value: [memoryId],
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause>
      memoryIdNotEqualTo(int memoryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [],
              upper: [memoryId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [memoryId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [memoryId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'memoryId',
              lower: [],
              upper: [memoryId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause>
      memoryIdGreaterThan(
    int memoryId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'memoryId',
        lower: [memoryId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause>
      memoryIdLessThan(
    int memoryId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'memoryId',
        lower: [],
        upper: [memoryId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterWhereClause> memoryIdBetween(
    int lowerMemoryId,
    int upperMemoryId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'memoryId',
        lower: [lowerMemoryId],
        includeLower: includeLower,
        upper: [upperMemoryId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FollowUpModelQueryFilter
    on QueryBuilder<FollowUpModel, FollowUpModel, QFilterCondition> {
  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      memoryIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      memoryIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'memoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      memoryIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'memoryId',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      memoryIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'memoryId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'question',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'question',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'question',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'question',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      questionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'question',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      scheduledAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      scheduledAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      scheduledAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scheduledAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      scheduledAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scheduledAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension FollowUpModelQueryObject
    on QueryBuilder<FollowUpModel, FollowUpModel, QFilterCondition> {}

extension FollowUpModelQueryLinks
    on QueryBuilder<FollowUpModel, FollowUpModel, QFilterCondition> {}

extension FollowUpModelQuerySortBy
    on QueryBuilder<FollowUpModel, FollowUpModel, QSortBy> {
  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> sortByMemoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy>
      sortByMemoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.desc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> sortByQuestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy>
      sortByQuestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.desc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> sortByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy>
      sortByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension FollowUpModelQuerySortThenBy
    on QueryBuilder<FollowUpModel, FollowUpModel, QSortThenBy> {
  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> thenByMemoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy>
      thenByMemoryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryId', Sort.desc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> thenByQuestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy>
      thenByQuestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.desc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> thenByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy>
      thenByScheduledAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scheduledAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension FollowUpModelQueryWhereDistinct
    on QueryBuilder<FollowUpModel, FollowUpModel, QDistinct> {
  QueryBuilder<FollowUpModel, FollowUpModel, QDistinct> distinctByMemoryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memoryId');
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QDistinct> distinctByQuestion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'question', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QDistinct>
      distinctByScheduledAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scheduledAt');
    });
  }

  QueryBuilder<FollowUpModel, FollowUpModel, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension FollowUpModelQueryProperty
    on QueryBuilder<FollowUpModel, FollowUpModel, QQueryProperty> {
  QueryBuilder<FollowUpModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FollowUpModel, int, QQueryOperations> memoryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memoryId');
    });
  }

  QueryBuilder<FollowUpModel, String, QQueryOperations> questionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'question');
    });
  }

  QueryBuilder<FollowUpModel, DateTime, QQueryOperations>
      scheduledAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scheduledAt');
    });
  }

  QueryBuilder<FollowUpModel, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
