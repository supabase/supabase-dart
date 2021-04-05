class Bucket {
  const Bucket({
    required this.id,
    required this.name,
    required this.owner,
    required this.createdAt,
    required this.updatedAt,
  });

  Bucket.fromJson(dynamic json)
      : assert(json is Map),
        id = json['id'] as String,
        name = json['name'] as String,
        owner = json['owner'] as String,
        createdAt = json['created_at'] as String,
        updatedAt = json['updated_at'] as String;

  final String id;
  final String name;
  final String owner;
  final String createdAt;
  final String updatedAt;
}

class FileObject {
  const FileObject({
    required this.name,
    required this.bucketId,
    required this.owner,
    required this.id,
    required this.updatedAt,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.metadata,
    required this.buckets,
  });

  FileObject.fromJson(dynamic json)
      : id = json['id'] as String?,
        name = json['name'] as String,
        bucketId = json['bucket_id'] as String?,
        owner = json['owner'] as String?,
        updatedAt = json['updated_at'] as String?,
        createdAt = json['created_at'] as String?,
        lastAccessedAt = json['last_accessed_at'] as String?,
        metadata = json['metadata'] != null ? Metadata.fromJson(json['metadata']) : null,
        buckets = json['buckets'] != null ? Bucket.fromJson(json['buckets']) : null;

  final String name;
  final String? bucketId;
  final String? owner;
  final String? id;
  final String? updatedAt;
  final String? createdAt;
  final String? lastAccessedAt;
  final Metadata? metadata;
  final Bucket? buckets;
}

class FileOptions {
  const FileOptions({required this.cacheControl});

  final String cacheControl;
}

class SearchOptions {
  const SearchOptions({this.limit, this.offset, this.sortBy});

  /// The number of files you want to be returned. */
  final int? limit;

  /// The starting position. */
  final int? offset;

  /// The column to sort by. Can be any column inside a FileObject. */
  final SortBy? sortBy;
}

class SortBy {
  const SortBy({this.column, this.order});

  final String? column;
  final String? order;
}

// TODO: need to check for metadata props. The api swagger doesnt have.
class Metadata {
  const Metadata({required this.name});

  Metadata.fromJson(dynamic json) : name = json['name'] as String?;

  final String? name;
}
