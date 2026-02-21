// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDeckItemCollection on Isar {
  IsarCollection<DeckItem> get deckItems => this.collection();
}

const DeckItemSchema = CollectionSchema(
  name: r'DeckItem',
  id: -1529322228897076487,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'newCardsLimit': PropertySchema(
      id: 2,
      name: r'newCardsLimit',
      type: IsarType.long,
    ),
    r'orderIndex': PropertySchema(
      id: 3,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'reviewsLimit': PropertySchema(
      id: 4,
      name: r'reviewsLimit',
      type: IsarType.long,
    )
  },
  estimateSize: _deckItemEstimateSize,
  serialize: _deckItemSerialize,
  deserialize: _deckItemDeserialize,
  deserializeProp: _deckItemDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'cards': LinkSchema(
      id: -6908950704847278653,
      name: r'cards',
      target: r'CardItem',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _deckItemGetId,
  getLinks: _deckItemGetLinks,
  attach: _deckItemAttach,
  version: '3.1.0+1',
);

int _deckItemEstimateSize(
  DeckItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _deckItemSerialize(
  DeckItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.name);
  writer.writeLong(offsets[2], object.newCardsLimit);
  writer.writeLong(offsets[3], object.orderIndex);
  writer.writeLong(offsets[4], object.reviewsLimit);
}

DeckItem _deckItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DeckItem();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.name = reader.readString(offsets[1]);
  object.newCardsLimit = reader.readLong(offsets[2]);
  object.orderIndex = reader.readLongOrNull(offsets[3]);
  object.reviewsLimit = reader.readLong(offsets[4]);
  return object;
}

P _deckItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _deckItemGetId(DeckItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _deckItemGetLinks(DeckItem object) {
  return [object.cards];
}

void _deckItemAttach(IsarCollection<dynamic> col, Id id, DeckItem object) {
  object.id = id;
  object.cards.attach(col, col.isar.collection<CardItem>(), r'cards', id);
}

extension DeckItemQueryWhereSort on QueryBuilder<DeckItem, DeckItem, QWhere> {
  QueryBuilder<DeckItem, DeckItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DeckItemQueryWhere on QueryBuilder<DeckItem, DeckItem, QWhereClause> {
  QueryBuilder<DeckItem, DeckItem, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DeckItem, DeckItem, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterWhereClause> idBetween(
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

extension DeckItemQueryFilter
    on QueryBuilder<DeckItem, DeckItem, QFilterCondition> {
  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> idBetween(
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

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> newCardsLimitEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'newCardsLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition>
      newCardsLimitGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'newCardsLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> newCardsLimitLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'newCardsLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> newCardsLimitBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'newCardsLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> orderIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderIndex',
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition>
      orderIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderIndex',
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> orderIndexEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> orderIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> orderIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> orderIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> reviewsLimitEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reviewsLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition>
      reviewsLimitGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reviewsLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> reviewsLimitLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reviewsLimit',
        value: value,
      ));
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> reviewsLimitBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reviewsLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DeckItemQueryObject
    on QueryBuilder<DeckItem, DeckItem, QFilterCondition> {}

extension DeckItemQueryLinks
    on QueryBuilder<DeckItem, DeckItem, QFilterCondition> {
  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> cards(
      FilterQuery<CardItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'cards');
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> cardsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'cards', length, true, length, true);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> cardsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'cards', 0, true, 0, true);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> cardsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'cards', 0, false, 999999, true);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> cardsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'cards', 0, true, length, include);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition>
      cardsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'cards', length, include, 999999, true);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterFilterCondition> cardsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'cards', lower, includeLower, upper, includeUpper);
    });
  }
}

extension DeckItemQuerySortBy on QueryBuilder<DeckItem, DeckItem, QSortBy> {
  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByNewCardsLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCardsLimit', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByNewCardsLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCardsLimit', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByReviewsLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewsLimit', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> sortByReviewsLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewsLimit', Sort.desc);
    });
  }
}

extension DeckItemQuerySortThenBy
    on QueryBuilder<DeckItem, DeckItem, QSortThenBy> {
  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByNewCardsLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCardsLimit', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByNewCardsLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newCardsLimit', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByReviewsLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewsLimit', Sort.asc);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QAfterSortBy> thenByReviewsLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reviewsLimit', Sort.desc);
    });
  }
}

extension DeckItemQueryWhereDistinct
    on QueryBuilder<DeckItem, DeckItem, QDistinct> {
  QueryBuilder<DeckItem, DeckItem, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DeckItem, DeckItem, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DeckItem, DeckItem, QDistinct> distinctByNewCardsLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'newCardsLimit');
    });
  }

  QueryBuilder<DeckItem, DeckItem, QDistinct> distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<DeckItem, DeckItem, QDistinct> distinctByReviewsLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reviewsLimit');
    });
  }
}

extension DeckItemQueryProperty
    on QueryBuilder<DeckItem, DeckItem, QQueryProperty> {
  QueryBuilder<DeckItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DeckItem, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DeckItem, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<DeckItem, int, QQueryOperations> newCardsLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'newCardsLimit');
    });
  }

  QueryBuilder<DeckItem, int?, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<DeckItem, int, QQueryOperations> reviewsLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reviewsLimit');
    });
  }
}
