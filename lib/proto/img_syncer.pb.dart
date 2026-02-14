// This is a generated file - do not edit.
//
// Generated from proto/img_syncer.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class ListByDateRequest extends $pb.GeneratedMessage {
  factory ListByDateRequest({
    $core.String? date,
    $core.int? offset,
    $core.int? maxReturn,
  }) {
    final result = create();
    if (date != null) result.date = date;
    if (offset != null) result.offset = offset;
    if (maxReturn != null) result.maxReturn = maxReturn;
    return result;
  }

  ListByDateRequest._();

  factory ListByDateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListByDateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListByDateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'date')
    ..aI(2, _omitFieldNames ? '' : 'offset')
    ..aI(3, _omitFieldNames ? '' : 'maxReturn', protoName: 'maxReturn')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListByDateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListByDateRequest copyWith(void Function(ListByDateRequest) updates) =>
      super.copyWith((message) => updates(message as ListByDateRequest))
          as ListByDateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListByDateRequest create() => ListByDateRequest._();
  @$core.override
  ListByDateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListByDateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListByDateRequest>(create);
  static ListByDateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get date => $_getSZ(0);
  @$pb.TagNumber(1)
  set date($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDate() => $_has(0);
  @$pb.TagNumber(1)
  void clearDate() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get maxReturn => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxReturn($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxReturn() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxReturn() => $_clearField(3);
}

class ListByDateResponse extends $pb.GeneratedMessage {
  factory ListByDateResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<$core.String>? paths,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (paths != null) result.paths.addAll(paths);
    return result;
  }

  ListByDateResponse._();

  factory ListByDateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListByDateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListByDateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPS(3, _omitFieldNames ? '' : 'paths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListByDateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListByDateResponse copyWith(void Function(ListByDateResponse) updates) =>
      super.copyWith((message) => updates(message as ListByDateResponse))
          as ListByDateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListByDateResponse create() => ListByDateResponse._();
  @$core.override
  ListByDateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListByDateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListByDateResponse>(create);
  static ListByDateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get paths => $_getList(2);
}

class DeleteRequest extends $pb.GeneratedMessage {
  factory DeleteRequest({
    $core.Iterable<$core.String>? paths,
  }) {
    final result = create();
    if (paths != null) result.paths.addAll(paths);
    return result;
  }

  DeleteRequest._();

  factory DeleteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'paths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRequest copyWith(void Function(DeleteRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteRequest))
          as DeleteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteRequest create() => DeleteRequest._();
  @$core.override
  DeleteRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteRequest>(create);
  static DeleteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get paths => $_getList(0);
}

class DeleteResponse extends $pb.GeneratedMessage {
  factory DeleteResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  DeleteResponse._();

  factory DeleteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResponse copyWith(void Function(DeleteResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteResponse))
          as DeleteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResponse create() => DeleteResponse._();
  @$core.override
  DeleteResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteResponse>(create);
  static DeleteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class FilterNotUploadedRequestInfo extends $pb.GeneratedMessage {
  factory FilterNotUploadedRequestInfo({
    $core.String? name,
    $core.String? date,
    $core.String? id,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (date != null) result.date = date;
    if (id != null) result.id = id;
    return result;
  }

  FilterNotUploadedRequestInfo._();

  factory FilterNotUploadedRequestInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilterNotUploadedRequestInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilterNotUploadedRequestInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'date')
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterNotUploadedRequestInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterNotUploadedRequestInfo copyWith(
          void Function(FilterNotUploadedRequestInfo) updates) =>
      super.copyWith(
              (message) => updates(message as FilterNotUploadedRequestInfo))
          as FilterNotUploadedRequestInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilterNotUploadedRequestInfo create() =>
      FilterNotUploadedRequestInfo._();
  @$core.override
  FilterNotUploadedRequestInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilterNotUploadedRequestInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilterNotUploadedRequestInfo>(create);
  static FilterNotUploadedRequestInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get date => $_getSZ(1);
  @$pb.TagNumber(2)
  set date($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearDate() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);
}

class FilterNotUploadedRequest extends $pb.GeneratedMessage {
  factory FilterNotUploadedRequest({
    $core.Iterable<FilterNotUploadedRequestInfo>? photos,
    $core.bool? isFinished,
  }) {
    final result = create();
    if (photos != null) result.photos.addAll(photos);
    if (isFinished != null) result.isFinished = isFinished;
    return result;
  }

  FilterNotUploadedRequest._();

  factory FilterNotUploadedRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilterNotUploadedRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilterNotUploadedRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..pPM<FilterNotUploadedRequestInfo>(1, _omitFieldNames ? '' : 'photos',
        subBuilder: FilterNotUploadedRequestInfo.create)
    ..aOB(2, _omitFieldNames ? '' : 'isFinished', protoName: 'isFinished')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterNotUploadedRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterNotUploadedRequest copyWith(
          void Function(FilterNotUploadedRequest) updates) =>
      super.copyWith((message) => updates(message as FilterNotUploadedRequest))
          as FilterNotUploadedRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilterNotUploadedRequest create() => FilterNotUploadedRequest._();
  @$core.override
  FilterNotUploadedRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilterNotUploadedRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilterNotUploadedRequest>(create);
  static FilterNotUploadedRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<FilterNotUploadedRequestInfo> get photos => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get isFinished => $_getBF(1);
  @$pb.TagNumber(2)
  set isFinished($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsFinished() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsFinished() => $_clearField(2);
}

class FilterNotUploadedResponse extends $pb.GeneratedMessage {
  factory FilterNotUploadedResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<$core.String>? notUploaedIDs,
    $core.bool? isFinished,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (notUploaedIDs != null) result.notUploaedIDs.addAll(notUploaedIDs);
    if (isFinished != null) result.isFinished = isFinished;
    return result;
  }

  FilterNotUploadedResponse._();

  factory FilterNotUploadedResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FilterNotUploadedResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FilterNotUploadedResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPS(3, _omitFieldNames ? '' : 'notUploaedIDs', protoName: 'notUploaedIDs')
    ..aOB(4, _omitFieldNames ? '' : 'isFinished', protoName: 'isFinished')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterNotUploadedResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FilterNotUploadedResponse copyWith(
          void Function(FilterNotUploadedResponse) updates) =>
      super.copyWith((message) => updates(message as FilterNotUploadedResponse))
          as FilterNotUploadedResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FilterNotUploadedResponse create() => FilterNotUploadedResponse._();
  @$core.override
  FilterNotUploadedResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FilterNotUploadedResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FilterNotUploadedResponse>(create);
  static FilterNotUploadedResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get notUploaedIDs => $_getList(2);

  @$pb.TagNumber(4)
  $core.bool get isFinished => $_getBF(3);
  @$pb.TagNumber(4)
  set isFinished($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsFinished() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsFinished() => $_clearField(4);
}

class SetDriveSMBRequest extends $pb.GeneratedMessage {
  factory SetDriveSMBRequest({
    $core.String? addr,
    $core.String? username,
    $core.String? password,
    $core.String? share,
    $core.String? root,
  }) {
    final result = create();
    if (addr != null) result.addr = addr;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    if (share != null) result.share = share;
    if (root != null) result.root = root;
    return result;
  }

  SetDriveSMBRequest._();

  factory SetDriveSMBRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveSMBRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveSMBRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'addr')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..aOS(4, _omitFieldNames ? '' : 'share')
    ..aOS(5, _omitFieldNames ? '' : 'root')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBRequest copyWith(void Function(SetDriveSMBRequest) updates) =>
      super.copyWith((message) => updates(message as SetDriveSMBRequest))
          as SetDriveSMBRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveSMBRequest create() => SetDriveSMBRequest._();
  @$core.override
  SetDriveSMBRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveSMBRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveSMBRequest>(create);
  static SetDriveSMBRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get addr => $_getSZ(0);
  @$pb.TagNumber(1)
  set addr($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddr() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddr() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get share => $_getSZ(3);
  @$pb.TagNumber(4)
  set share($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShare() => $_has(3);
  @$pb.TagNumber(4)
  void clearShare() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get root => $_getSZ(4);
  @$pb.TagNumber(5)
  set root($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRoot() => $_has(4);
  @$pb.TagNumber(5)
  void clearRoot() => $_clearField(5);
}

class SetDriveSMBResponse extends $pb.GeneratedMessage {
  factory SetDriveSMBResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  SetDriveSMBResponse._();

  factory SetDriveSMBResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveSMBResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveSMBResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBResponse copyWith(void Function(SetDriveSMBResponse) updates) =>
      super.copyWith((message) => updates(message as SetDriveSMBResponse))
          as SetDriveSMBResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveSMBResponse create() => SetDriveSMBResponse._();
  @$core.override
  SetDriveSMBResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveSMBResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveSMBResponse>(create);
  static SetDriveSMBResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class ListDriveSMBSharesRequest extends $pb.GeneratedMessage {
  factory ListDriveSMBSharesRequest() => create();

  ListDriveSMBSharesRequest._();

  factory ListDriveSMBSharesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveSMBSharesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveSMBSharesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBSharesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBSharesRequest copyWith(
          void Function(ListDriveSMBSharesRequest) updates) =>
      super.copyWith((message) => updates(message as ListDriveSMBSharesRequest))
          as ListDriveSMBSharesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveSMBSharesRequest create() => ListDriveSMBSharesRequest._();
  @$core.override
  ListDriveSMBSharesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveSMBSharesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveSMBSharesRequest>(create);
  static ListDriveSMBSharesRequest? _defaultInstance;
}

class ListDriveSMBSharesResponse extends $pb.GeneratedMessage {
  factory ListDriveSMBSharesResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<$core.String>? shares,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (shares != null) result.shares.addAll(shares);
    return result;
  }

  ListDriveSMBSharesResponse._();

  factory ListDriveSMBSharesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveSMBSharesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveSMBSharesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPS(3, _omitFieldNames ? '' : 'shares')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBSharesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBSharesResponse copyWith(
          void Function(ListDriveSMBSharesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListDriveSMBSharesResponse))
          as ListDriveSMBSharesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveSMBSharesResponse create() => ListDriveSMBSharesResponse._();
  @$core.override
  ListDriveSMBSharesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveSMBSharesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveSMBSharesResponse>(create);
  static ListDriveSMBSharesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get shares => $_getList(2);
}

class ListDriveSMBDirRequest extends $pb.GeneratedMessage {
  factory ListDriveSMBDirRequest({
    $core.String? share,
    $core.String? dir,
  }) {
    final result = create();
    if (share != null) result.share = share;
    if (dir != null) result.dir = dir;
    return result;
  }

  ListDriveSMBDirRequest._();

  factory ListDriveSMBDirRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveSMBDirRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveSMBDirRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'share')
    ..aOS(2, _omitFieldNames ? '' : 'dir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBDirRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBDirRequest copyWith(
          void Function(ListDriveSMBDirRequest) updates) =>
      super.copyWith((message) => updates(message as ListDriveSMBDirRequest))
          as ListDriveSMBDirRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveSMBDirRequest create() => ListDriveSMBDirRequest._();
  @$core.override
  ListDriveSMBDirRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveSMBDirRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveSMBDirRequest>(create);
  static ListDriveSMBDirRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get share => $_getSZ(0);
  @$pb.TagNumber(1)
  set share($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShare() => $_has(0);
  @$pb.TagNumber(1)
  void clearShare() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get dir => $_getSZ(1);
  @$pb.TagNumber(2)
  set dir($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);
}

class ListDriveSMBDirResponse extends $pb.GeneratedMessage {
  factory ListDriveSMBDirResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<$core.String>? dirs,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (dirs != null) result.dirs.addAll(dirs);
    return result;
  }

  ListDriveSMBDirResponse._();

  factory ListDriveSMBDirResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveSMBDirResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveSMBDirResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPS(3, _omitFieldNames ? '' : 'dirs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBDirResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveSMBDirResponse copyWith(
          void Function(ListDriveSMBDirResponse) updates) =>
      super.copyWith((message) => updates(message as ListDriveSMBDirResponse))
          as ListDriveSMBDirResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveSMBDirResponse create() => ListDriveSMBDirResponse._();
  @$core.override
  ListDriveSMBDirResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveSMBDirResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveSMBDirResponse>(create);
  static ListDriveSMBDirResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get dirs => $_getList(2);
}

class SetDriveSMBShareRequest extends $pb.GeneratedMessage {
  factory SetDriveSMBShareRequest({
    $core.String? share,
    $core.String? root,
  }) {
    final result = create();
    if (share != null) result.share = share;
    if (root != null) result.root = root;
    return result;
  }

  SetDriveSMBShareRequest._();

  factory SetDriveSMBShareRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveSMBShareRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveSMBShareRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'share')
    ..aOS(2, _omitFieldNames ? '' : 'root')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBShareRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBShareRequest copyWith(
          void Function(SetDriveSMBShareRequest) updates) =>
      super.copyWith((message) => updates(message as SetDriveSMBShareRequest))
          as SetDriveSMBShareRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveSMBShareRequest create() => SetDriveSMBShareRequest._();
  @$core.override
  SetDriveSMBShareRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveSMBShareRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveSMBShareRequest>(create);
  static SetDriveSMBShareRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get share => $_getSZ(0);
  @$pb.TagNumber(1)
  set share($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShare() => $_has(0);
  @$pb.TagNumber(1)
  void clearShare() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get root => $_getSZ(1);
  @$pb.TagNumber(2)
  set root($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoot() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoot() => $_clearField(2);
}

class SetDriveSMBShareResponse extends $pb.GeneratedMessage {
  factory SetDriveSMBShareResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  SetDriveSMBShareResponse._();

  factory SetDriveSMBShareResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveSMBShareResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveSMBShareResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBShareResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveSMBShareResponse copyWith(
          void Function(SetDriveSMBShareResponse) updates) =>
      super.copyWith((message) => updates(message as SetDriveSMBShareResponse))
          as SetDriveSMBShareResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveSMBShareResponse create() => SetDriveSMBShareResponse._();
  @$core.override
  SetDriveSMBShareResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveSMBShareResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveSMBShareResponse>(create);
  static SetDriveSMBShareResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class SetDriveWebdavRequest extends $pb.GeneratedMessage {
  factory SetDriveWebdavRequest({
    $core.String? addr,
    $core.String? username,
    $core.String? password,
    $core.String? root,
  }) {
    final result = create();
    if (addr != null) result.addr = addr;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    if (root != null) result.root = root;
    return result;
  }

  SetDriveWebdavRequest._();

  factory SetDriveWebdavRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveWebdavRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveWebdavRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'addr')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..aOS(4, _omitFieldNames ? '' : 'root')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveWebdavRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveWebdavRequest copyWith(
          void Function(SetDriveWebdavRequest) updates) =>
      super.copyWith((message) => updates(message as SetDriveWebdavRequest))
          as SetDriveWebdavRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveWebdavRequest create() => SetDriveWebdavRequest._();
  @$core.override
  SetDriveWebdavRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveWebdavRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveWebdavRequest>(create);
  static SetDriveWebdavRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get addr => $_getSZ(0);
  @$pb.TagNumber(1)
  set addr($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddr() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddr() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get root => $_getSZ(3);
  @$pb.TagNumber(4)
  set root($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRoot() => $_has(3);
  @$pb.TagNumber(4)
  void clearRoot() => $_clearField(4);
}

class SetDriveWebdavResponse extends $pb.GeneratedMessage {
  factory SetDriveWebdavResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  SetDriveWebdavResponse._();

  factory SetDriveWebdavResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveWebdavResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveWebdavResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveWebdavResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveWebdavResponse copyWith(
          void Function(SetDriveWebdavResponse) updates) =>
      super.copyWith((message) => updates(message as SetDriveWebdavResponse))
          as SetDriveWebdavResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveWebdavResponse create() => SetDriveWebdavResponse._();
  @$core.override
  SetDriveWebdavResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveWebdavResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveWebdavResponse>(create);
  static SetDriveWebdavResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class ListDriveWebdavDirRequest extends $pb.GeneratedMessage {
  factory ListDriveWebdavDirRequest({
    $core.String? dir,
  }) {
    final result = create();
    if (dir != null) result.dir = dir;
    return result;
  }

  ListDriveWebdavDirRequest._();

  factory ListDriveWebdavDirRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveWebdavDirRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveWebdavDirRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'dir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveWebdavDirRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveWebdavDirRequest copyWith(
          void Function(ListDriveWebdavDirRequest) updates) =>
      super.copyWith((message) => updates(message as ListDriveWebdavDirRequest))
          as ListDriveWebdavDirRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveWebdavDirRequest create() => ListDriveWebdavDirRequest._();
  @$core.override
  ListDriveWebdavDirRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveWebdavDirRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveWebdavDirRequest>(create);
  static ListDriveWebdavDirRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dir => $_getSZ(0);
  @$pb.TagNumber(1)
  set dir($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDir() => $_has(0);
  @$pb.TagNumber(1)
  void clearDir() => $_clearField(1);
}

class ListDriveWebdavDirResponse extends $pb.GeneratedMessage {
  factory ListDriveWebdavDirResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<$core.String>? dirs,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (dirs != null) result.dirs.addAll(dirs);
    return result;
  }

  ListDriveWebdavDirResponse._();

  factory ListDriveWebdavDirResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveWebdavDirResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveWebdavDirResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPS(3, _omitFieldNames ? '' : 'dirs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveWebdavDirResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveWebdavDirResponse copyWith(
          void Function(ListDriveWebdavDirResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListDriveWebdavDirResponse))
          as ListDriveWebdavDirResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveWebdavDirResponse create() => ListDriveWebdavDirResponse._();
  @$core.override
  ListDriveWebdavDirResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveWebdavDirResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveWebdavDirResponse>(create);
  static ListDriveWebdavDirResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get dirs => $_getList(2);
}

class SetDriveNFSRequest extends $pb.GeneratedMessage {
  factory SetDriveNFSRequest({
    $core.String? addr,
    $core.String? root,
  }) {
    final result = create();
    if (addr != null) result.addr = addr;
    if (root != null) result.root = root;
    return result;
  }

  SetDriveNFSRequest._();

  factory SetDriveNFSRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveNFSRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveNFSRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'addr')
    ..aOS(2, _omitFieldNames ? '' : 'root')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveNFSRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveNFSRequest copyWith(void Function(SetDriveNFSRequest) updates) =>
      super.copyWith((message) => updates(message as SetDriveNFSRequest))
          as SetDriveNFSRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveNFSRequest create() => SetDriveNFSRequest._();
  @$core.override
  SetDriveNFSRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveNFSRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveNFSRequest>(create);
  static SetDriveNFSRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get addr => $_getSZ(0);
  @$pb.TagNumber(1)
  set addr($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddr() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddr() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get root => $_getSZ(1);
  @$pb.TagNumber(2)
  set root($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoot() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoot() => $_clearField(2);
}

class SetDriveNFSResponse extends $pb.GeneratedMessage {
  factory SetDriveNFSResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  SetDriveNFSResponse._();

  factory SetDriveNFSResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveNFSResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveNFSResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveNFSResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveNFSResponse copyWith(void Function(SetDriveNFSResponse) updates) =>
      super.copyWith((message) => updates(message as SetDriveNFSResponse))
          as SetDriveNFSResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveNFSResponse create() => SetDriveNFSResponse._();
  @$core.override
  SetDriveNFSResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveNFSResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveNFSResponse>(create);
  static SetDriveNFSResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class ListDriveNFSDirRequest extends $pb.GeneratedMessage {
  factory ListDriveNFSDirRequest({
    $core.String? dir,
  }) {
    final result = create();
    if (dir != null) result.dir = dir;
    return result;
  }

  ListDriveNFSDirRequest._();

  factory ListDriveNFSDirRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveNFSDirRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveNFSDirRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'dir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveNFSDirRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveNFSDirRequest copyWith(
          void Function(ListDriveNFSDirRequest) updates) =>
      super.copyWith((message) => updates(message as ListDriveNFSDirRequest))
          as ListDriveNFSDirRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveNFSDirRequest create() => ListDriveNFSDirRequest._();
  @$core.override
  ListDriveNFSDirRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveNFSDirRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveNFSDirRequest>(create);
  static ListDriveNFSDirRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dir => $_getSZ(0);
  @$pb.TagNumber(1)
  set dir($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDir() => $_has(0);
  @$pb.TagNumber(1)
  void clearDir() => $_clearField(1);
}

class ListDriveNFSDirResponse extends $pb.GeneratedMessage {
  factory ListDriveNFSDirResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<$core.String>? dirs,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (dirs != null) result.dirs.addAll(dirs);
    return result;
  }

  ListDriveNFSDirResponse._();

  factory ListDriveNFSDirResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListDriveNFSDirResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDriveNFSDirResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPS(3, _omitFieldNames ? '' : 'dirs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveNFSDirResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDriveNFSDirResponse copyWith(
          void Function(ListDriveNFSDirResponse) updates) =>
      super.copyWith((message) => updates(message as ListDriveNFSDirResponse))
          as ListDriveNFSDirResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListDriveNFSDirResponse create() => ListDriveNFSDirResponse._();
  @$core.override
  ListDriveNFSDirResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListDriveNFSDirResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDriveNFSDirResponse>(create);
  static ListDriveNFSDirResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get dirs => $_getList(2);
}

class SetDriveBaiduNetDiskRequest extends $pb.GeneratedMessage {
  factory SetDriveBaiduNetDiskRequest({
    $core.String? refreshToken,
    $core.String? accessToken,
    $core.String? tmpDir,
  }) {
    final result = create();
    if (refreshToken != null) result.refreshToken = refreshToken;
    if (accessToken != null) result.accessToken = accessToken;
    if (tmpDir != null) result.tmpDir = tmpDir;
    return result;
  }

  SetDriveBaiduNetDiskRequest._();

  factory SetDriveBaiduNetDiskRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveBaiduNetDiskRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveBaiduNetDiskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'refreshToken', protoName: 'refreshToken')
    ..aOS(2, _omitFieldNames ? '' : 'accessToken', protoName: 'accessToken')
    ..aOS(3, _omitFieldNames ? '' : 'tmpDir', protoName: 'tmpDir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveBaiduNetDiskRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveBaiduNetDiskRequest copyWith(
          void Function(SetDriveBaiduNetDiskRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetDriveBaiduNetDiskRequest))
          as SetDriveBaiduNetDiskRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveBaiduNetDiskRequest create() =>
      SetDriveBaiduNetDiskRequest._();
  @$core.override
  SetDriveBaiduNetDiskRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveBaiduNetDiskRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveBaiduNetDiskRequest>(create);
  static SetDriveBaiduNetDiskRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get refreshToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set refreshToken($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRefreshToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearRefreshToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get accessToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set accessToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccessToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccessToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get tmpDir => $_getSZ(2);
  @$pb.TagNumber(3)
  set tmpDir($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTmpDir() => $_has(2);
  @$pb.TagNumber(3)
  void clearTmpDir() => $_clearField(3);
}

class SetDriveBaiduNetDiskResponse extends $pb.GeneratedMessage {
  factory SetDriveBaiduNetDiskResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  SetDriveBaiduNetDiskResponse._();

  factory SetDriveBaiduNetDiskResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetDriveBaiduNetDiskResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetDriveBaiduNetDiskResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveBaiduNetDiskResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetDriveBaiduNetDiskResponse copyWith(
          void Function(SetDriveBaiduNetDiskResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SetDriveBaiduNetDiskResponse))
          as SetDriveBaiduNetDiskResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetDriveBaiduNetDiskResponse create() =>
      SetDriveBaiduNetDiskResponse._();
  @$core.override
  SetDriveBaiduNetDiskResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetDriveBaiduNetDiskResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetDriveBaiduNetDiskResponse>(create);
  static SetDriveBaiduNetDiskResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class StartBaiduNetdiskLoginRequest extends $pb.GeneratedMessage {
  factory StartBaiduNetdiskLoginRequest({
    $core.String? tmpDir,
  }) {
    final result = create();
    if (tmpDir != null) result.tmpDir = tmpDir;
    return result;
  }

  StartBaiduNetdiskLoginRequest._();

  factory StartBaiduNetdiskLoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartBaiduNetdiskLoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartBaiduNetdiskLoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'tmpDir', protoName: 'tmpDir')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartBaiduNetdiskLoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartBaiduNetdiskLoginRequest copyWith(
          void Function(StartBaiduNetdiskLoginRequest) updates) =>
      super.copyWith(
              (message) => updates(message as StartBaiduNetdiskLoginRequest))
          as StartBaiduNetdiskLoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBaiduNetdiskLoginRequest create() =>
      StartBaiduNetdiskLoginRequest._();
  @$core.override
  StartBaiduNetdiskLoginRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartBaiduNetdiskLoginRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartBaiduNetdiskLoginRequest>(create);
  static StartBaiduNetdiskLoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get tmpDir => $_getSZ(0);
  @$pb.TagNumber(1)
  set tmpDir($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTmpDir() => $_has(0);
  @$pb.TagNumber(1)
  void clearTmpDir() => $_clearField(1);
}

class StartBaiduNetdiskLoginResponse extends $pb.GeneratedMessage {
  factory StartBaiduNetdiskLoginResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? refreshToken,
    $core.String? accessToken,
    $fixnum.Int64? exiresAt,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (refreshToken != null) result.refreshToken = refreshToken;
    if (accessToken != null) result.accessToken = accessToken;
    if (exiresAt != null) result.exiresAt = exiresAt;
    return result;
  }

  StartBaiduNetdiskLoginResponse._();

  factory StartBaiduNetdiskLoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartBaiduNetdiskLoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartBaiduNetdiskLoginResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'refreshToken', protoName: 'refreshToken')
    ..aOS(4, _omitFieldNames ? '' : 'accessToken', protoName: 'accessToken')
    ..aInt64(5, _omitFieldNames ? '' : 'exiresAt', protoName: 'exiresAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartBaiduNetdiskLoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartBaiduNetdiskLoginResponse copyWith(
          void Function(StartBaiduNetdiskLoginResponse) updates) =>
      super.copyWith(
              (message) => updates(message as StartBaiduNetdiskLoginResponse))
          as StartBaiduNetdiskLoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBaiduNetdiskLoginResponse create() =>
      StartBaiduNetdiskLoginResponse._();
  @$core.override
  StartBaiduNetdiskLoginResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartBaiduNetdiskLoginResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartBaiduNetdiskLoginResponse>(create);
  static StartBaiduNetdiskLoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get refreshToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set refreshToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRefreshToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearRefreshToken() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get accessToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set accessToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAccessToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearAccessToken() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get exiresAt => $_getI64(4);
  @$pb.TagNumber(5)
  set exiresAt($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasExiresAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearExiresAt() => $_clearField(5);
}

class MoveToTrashRequest extends $pb.GeneratedMessage {
  factory MoveToTrashRequest({
    $core.Iterable<$core.String>? paths,
  }) {
    final result = create();
    if (paths != null) result.paths.addAll(paths);
    return result;
  }

  MoveToTrashRequest._();

  factory MoveToTrashRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MoveToTrashRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MoveToTrashRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'paths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveToTrashRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveToTrashRequest copyWith(void Function(MoveToTrashRequest) updates) =>
      super.copyWith((message) => updates(message as MoveToTrashRequest))
          as MoveToTrashRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MoveToTrashRequest create() => MoveToTrashRequest._();
  @$core.override
  MoveToTrashRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MoveToTrashRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MoveToTrashRequest>(create);
  static MoveToTrashRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get paths => $_getList(0);
}

class MoveToTrashResponse extends $pb.GeneratedMessage {
  factory MoveToTrashResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  MoveToTrashResponse._();

  factory MoveToTrashResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MoveToTrashResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MoveToTrashResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveToTrashResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveToTrashResponse copyWith(void Function(MoveToTrashResponse) updates) =>
      super.copyWith((message) => updates(message as MoveToTrashResponse))
          as MoveToTrashResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MoveToTrashResponse create() => MoveToTrashResponse._();
  @$core.override
  MoveToTrashResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MoveToTrashResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MoveToTrashResponse>(create);
  static MoveToTrashResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class TrashItem extends $pb.GeneratedMessage {
  factory TrashItem({
    $core.String? originalPath,
    $core.String? trashPath,
    $fixnum.Int64? trashedAt,
    $fixnum.Int64? size,
  }) {
    final result = create();
    if (originalPath != null) result.originalPath = originalPath;
    if (trashPath != null) result.trashPath = trashPath;
    if (trashedAt != null) result.trashedAt = trashedAt;
    if (size != null) result.size = size;
    return result;
  }

  TrashItem._();

  factory TrashItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrashItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrashItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'originalPath', protoName: 'originalPath')
    ..aOS(2, _omitFieldNames ? '' : 'trashPath', protoName: 'trashPath')
    ..aInt64(3, _omitFieldNames ? '' : 'trashedAt', protoName: 'trashedAt')
    ..aInt64(4, _omitFieldNames ? '' : 'size')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrashItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrashItem copyWith(void Function(TrashItem) updates) =>
      super.copyWith((message) => updates(message as TrashItem)) as TrashItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrashItem create() => TrashItem._();
  @$core.override
  TrashItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrashItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrashItem>(create);
  static TrashItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get originalPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set originalPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOriginalPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearOriginalPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get trashPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set trashPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTrashPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrashPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get trashedAt => $_getI64(2);
  @$pb.TagNumber(3)
  set trashedAt($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTrashedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrashedAt() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);
}

class ListTrashRequest extends $pb.GeneratedMessage {
  factory ListTrashRequest({
    $core.int? offset,
    $core.int? maxReturn,
  }) {
    final result = create();
    if (offset != null) result.offset = offset;
    if (maxReturn != null) result.maxReturn = maxReturn;
    return result;
  }

  ListTrashRequest._();

  factory ListTrashRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTrashRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTrashRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'offset')
    ..aI(2, _omitFieldNames ? '' : 'maxReturn', protoName: 'maxReturn')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTrashRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTrashRequest copyWith(void Function(ListTrashRequest) updates) =>
      super.copyWith((message) => updates(message as ListTrashRequest))
          as ListTrashRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTrashRequest create() => ListTrashRequest._();
  @$core.override
  ListTrashRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTrashRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTrashRequest>(create);
  static ListTrashRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get offset => $_getIZ(0);
  @$pb.TagNumber(1)
  set offset($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffset() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffset() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get maxReturn => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxReturn($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxReturn() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxReturn() => $_clearField(2);
}

class ListTrashResponse extends $pb.GeneratedMessage {
  factory ListTrashResponse({
    $core.bool? success,
    $core.String? message,
    $core.Iterable<TrashItem>? items,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (items != null) result.items.addAll(items);
    return result;
  }

  ListTrashResponse._();

  factory ListTrashResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTrashResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTrashResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..pPM<TrashItem>(3, _omitFieldNames ? '' : 'items',
        subBuilder: TrashItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTrashResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTrashResponse copyWith(void Function(ListTrashResponse) updates) =>
      super.copyWith((message) => updates(message as ListTrashResponse))
          as ListTrashResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTrashResponse create() => ListTrashResponse._();
  @$core.override
  ListTrashResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListTrashResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTrashResponse>(create);
  static ListTrashResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<TrashItem> get items => $_getList(2);
}

class RestoreFromTrashRequest extends $pb.GeneratedMessage {
  factory RestoreFromTrashRequest({
    $core.Iterable<$core.String>? trashPaths,
  }) {
    final result = create();
    if (trashPaths != null) result.trashPaths.addAll(trashPaths);
    return result;
  }

  RestoreFromTrashRequest._();

  factory RestoreFromTrashRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RestoreFromTrashRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RestoreFromTrashRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'trashPaths', protoName: 'trashPaths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestoreFromTrashRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestoreFromTrashRequest copyWith(
          void Function(RestoreFromTrashRequest) updates) =>
      super.copyWith((message) => updates(message as RestoreFromTrashRequest))
          as RestoreFromTrashRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RestoreFromTrashRequest create() => RestoreFromTrashRequest._();
  @$core.override
  RestoreFromTrashRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RestoreFromTrashRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RestoreFromTrashRequest>(create);
  static RestoreFromTrashRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get trashPaths => $_getList(0);
}

class RestoreFromTrashResponse extends $pb.GeneratedMessage {
  factory RestoreFromTrashResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  RestoreFromTrashResponse._();

  factory RestoreFromTrashResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RestoreFromTrashResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RestoreFromTrashResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestoreFromTrashResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RestoreFromTrashResponse copyWith(
          void Function(RestoreFromTrashResponse) updates) =>
      super.copyWith((message) => updates(message as RestoreFromTrashResponse))
          as RestoreFromTrashResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RestoreFromTrashResponse create() => RestoreFromTrashResponse._();
  @$core.override
  RestoreFromTrashResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RestoreFromTrashResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RestoreFromTrashResponse>(create);
  static RestoreFromTrashResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class EmptyTrashRequest extends $pb.GeneratedMessage {
  factory EmptyTrashRequest() => create();

  EmptyTrashRequest._();

  factory EmptyTrashRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EmptyTrashRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmptyTrashRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyTrashRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyTrashRequest copyWith(void Function(EmptyTrashRequest) updates) =>
      super.copyWith((message) => updates(message as EmptyTrashRequest))
          as EmptyTrashRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EmptyTrashRequest create() => EmptyTrashRequest._();
  @$core.override
  EmptyTrashRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EmptyTrashRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EmptyTrashRequest>(create);
  static EmptyTrashRequest? _defaultInstance;
}

class EmptyTrashResponse extends $pb.GeneratedMessage {
  factory EmptyTrashResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  EmptyTrashResponse._();

  factory EmptyTrashResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EmptyTrashResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EmptyTrashResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'img_syncer'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyTrashResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EmptyTrashResponse copyWith(void Function(EmptyTrashResponse) updates) =>
      super.copyWith((message) => updates(message as EmptyTrashResponse))
          as EmptyTrashResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EmptyTrashResponse create() => EmptyTrashResponse._();
  @$core.override
  EmptyTrashResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EmptyTrashResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EmptyTrashResponse>(create);
  static EmptyTrashResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
