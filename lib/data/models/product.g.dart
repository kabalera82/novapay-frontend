// lib/data/models/product.g.dart
part of 'product.dart';

// Adaptado manualmente siguiendo user.g.dart

const ProductSchema = CollectionSchema(
  name: r'Product',
  id: 9876543210987654321, // Cambia por un id único
  properties: {
    r'name': PropertySchema(id: 0, name: r'name', type: IsarType.string),
    r'price': PropertySchema(id: 1, name: r'price', type: IsarType.double),
    r'costPrice': PropertySchema(id: 2, name: r'costPrice', type: IsarType.double),
    r'stock': PropertySchema(id: 3, name: r'stock', type: IsarType.long),
    r'category': PropertySchema(id: 4, name: r'category', type: IsarType.string),
    r'barcode': PropertySchema(id: 5, name: r'barcode', type: IsarType.string),
    r'imagePath': PropertySchema(id: 6, name: r'imagePath', type: IsarType.string),
    r'taxRate': PropertySchema(id: 7, name: r'taxRate', type: IsarType.double),
  },
  estimateSize: _productEstimateSize,
  serialize: _productSerialize,
  deserialize: _productDeserialize,

  part of 'product.dart';

  extension GetProductCollection on Isar {
    IsarCollection<Product> get products => this.collection();
  }

  const ProductSchema = CollectionSchema(
    name: r'Product',
    id: 9876543210987654321,
    properties: {
      r'barcode': PropertySchema(id: 0, name: r'barcode', type: IsarType.string),
      r'category': PropertySchema(id: 1, name: r'category', type: IsarType.string),
      r'costPrice': PropertySchema(id: 2, name: r'costPrice', type: IsarType.double),
      r'imagePath': PropertySchema(id: 3, name: r'imagePath', type: IsarType.string),
      r'name': PropertySchema(id: 4, name: r'name', type: IsarType.string),
      r'price': PropertySchema(id: 5, name: r'price', type: IsarType.double),
      r'stock': PropertySchema(id: 6, name: r'stock', type: IsarType.long),
      r'taxRate': PropertySchema(id: 7, name: r'taxRate', type: IsarType.double),
    },
    estimateSize: _productEstimateSize,
    serialize: _productSerialize,
    deserialize: _productDeserialize,
    deserializeProp: _productDeserializeProp,
    idName: r'id',
    indexes: {},
    links: {},
    embeddedSchemas: {},
    getId: _productGetId,
    getLinks: _productGetLinks,
    attach: _productAttach,
    version: '3.1.0+1',
  );

  int _productEstimateSize(Product object, List<int> offsets, Map<Type, List<int>> allOffsets) {
    var bytesCount = offsets.last;
    if (object.barcode != null) bytesCount += 3 + object.barcode!.length * 3;
    if (object.category != null) bytesCount += 3 + object.category!.length * 3;
    if (object.costPrice != null) bytesCount += 8;
    if (object.imagePath != null) bytesCount += 3 + object.imagePath!.length * 3;
    bytesCount += 3 + object.name.length * 3;
    bytesCount += 8; // price
    bytesCount += 8; // stock
    bytesCount += 8; // taxRate
    return bytesCount;
  }

  void _productSerialize(Product object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
    writer.writeString(offsets[0], object.barcode);
    writer.writeString(offsets[1], object.category);
    writer.writeDouble(offsets[2], object.costPrice);
    writer.writeString(offsets[3], object.imagePath);
    writer.writeString(offsets[4], object.name);
    writer.writeDouble(offsets[5], object.price);
    writer.writeLong(offsets[6], object.stock);
    writer.writeDouble(offsets[7], object.taxRate);
  }

  Product _productDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
    final object = Product();
    object.id = id;
    object.barcode = reader.readStringOrNull(offsets[0]);
    object.category = reader.readStringOrNull(offsets[1]);
    object.costPrice = reader.readDoubleOrNull(offsets[2]);
    object.imagePath = reader.readStringOrNull(offsets[3]);
    object.name = reader.readString(offsets[4]);
    object.price = reader.readDouble(offsets[5]);
    object.stock = reader.readLong(offsets[6]);
    object.taxRate = reader.readDouble(offsets[7]);
    return object;
  }

  P _productDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
    switch (propertyId) {
      case 0:
        return (reader.readStringOrNull(offset)) as P;
      case 1:
        return (reader.readStringOrNull(offset)) as P;
      case 2:
        return (reader.readDoubleOrNull(offset)) as P;
      case 3:
        return (reader.readStringOrNull(offset)) as P;
      case 4:
        return (reader.readString(offset)) as P;
      case 5:
        return (reader.readDouble(offset)) as P;
      case 6:
        return (reader.readLong(offset)) as P;
      case 7:
        return (reader.readDouble(offset)) as P;
      default:
        throw IsarError('Unknown property with id $propertyId');
    }
  }

  Id _productGetId(Product object) => object.id;
  List<IsarLinkBase<dynamic>> _productGetLinks(Product object) => [];
  void _productAttach(IsarCollection<dynamic> col, Id id, Product object) => object.id = id;
